//
//  Copyright 2019-2020 SiniCloud. All rights reserved.
//  Use of this source code is governed by a BSD-style license that can be
//  found in the LICENSE.md file.
//

//
//  MARK: Imports.
//
import Foundation
import AVFoundation

//
//  MARK: Constants.
//

//
//  The buffer size needs to be able to carry at least 3 minutes of audio data.
//
//  The size of 16-bit audio data with a sampling rate of 16000 for 3 minutes
//  is 5760000 bytes, calculation is as follows:
//
//          16000 * 2 * 60 * 3 = 5760000 bytes
//
//  If each buffer contains 2048 packets, and the size of each packat is
//  16 bits (2B), the number of buffers that audio data has is at least 1406,
//  calculation is as follows:
//
//          5760000 / (2048 * 2) = 1406
//
//  In binary, round up to 2048.
//
fileprivate let PACKET_NUMBER_PRE_BUFFER = 2048
fileprivate let AUDIO_QUEUE_BUFFERS_COUNT = 2048

//
//  Globals.
//
fileprivate var g_AudioQueueLock = DispatchSemaphore(value: 1)

//
//  MARK: Struct.
//

///
///  Player.
///
fileprivate struct PlayerContext {
    var mAudioQueueBuffers = [AudioQueueBufferRef]()
    var mAudioQueueBuffersBusy = [Bool]()
    var mAudioQueueIsRunningHandler: () -> Void = {}
}

//
//  MARK: Public functions.
//

///
///  Output audio queue handler.
///
///  - Parameters:
///    - userInfo: Context.
///    - audioQueue: Audio queue object.
///    - buffer: Buffer object.
///
fileprivate func HandleAudioQueueOutputCallback(
    userInfo: UnsafeMutableRawPointer?,
    audioQueue: AudioQueueRef,
    buffer: AudioQueueBufferRef
) {
    //
    //  Lock.
    //
    g_AudioQueueLock.wait()
    defer {
        
        //
        //  Unlock.
        //
        g_AudioQueueLock.signal()
    }
    
    if let ctx = userInfo?.assumingMemoryBound(to: PlayerContext.self) {
        for i in 0..<ctx.pointee.mAudioQueueBuffers.count {
            if ctx.pointee.mAudioQueueBuffers[i] == buffer {
                ctx.pointee.mAudioQueueBuffersBusy[i] = false
            }
        }
    }
}

///
/// Handle audio queue 'isrunning' event.
///
/// - Parameters:
///   - userInfo: Context.
///   - aq: Audio queue reference.
///   - inID: Property ID.
///
fileprivate func HandleAudioQueueIsRunningCallback(
    context: UnsafeMutableRawPointer?,
    aq: AudioQueueRef,
    inID: AudioQueuePropertyID
) {
    //
    //  Lock.
    //
    g_AudioQueueLock.wait()
    defer {
        
        //
        //  Unlock.
        //
        g_AudioQueueLock.signal()
    }
            
    if let ctx = context?.assumingMemoryBound(to: PlayerContext.self) {
        ctx.pointee.mAudioQueueIsRunningHandler()
    }
}

//
//  MARK: Enum.
//

enum XAPPlayerStatus {
    case wait
    case running
    case closing
    case closed
}

//
//  MARK: Classes.
//

///
///  XAP streaming player.
///
class XAPPlayer {
    
    //
    //  MARK: XAPPlayer members.
    //
    
    //  Player context.
    fileprivate var m_PlayerContext = PlayerContext()
    
    //  Audio queue object.
    private var m_AudioQueue: AudioQueueRef!
    
    //  Status.
    private var m_Status: XAPPlayerStatus = .wait
    
    //  Buffer size.
    private var m_BufferByteSize: UInt32!
        
    //
    //  MARK: XAPPlayer private methods.
    //
    
    init() {
        self.registerAudioQueueIsRunningEvent(handler: {})
    }
    
    private func audioQueueCallingAssert(_ status: OSStatus) throws {
        if status != noErr {
            throw XAPError(message: "An unexpected error occurred while " +
                                "calling Apple API. (osstatus = \"\(status)\")")
        }
    }

    ///
    ///  Allocate player.
    ///
    ///  - Throws: Raised if allocation was failed.
    ///
    private func allocPlayer(dataFormat: AudioStreamBasicDescription) throws {
        var vDataFormat = dataFormat
        
        //  Create audio queue.
        try audioQueueCallingAssert(AudioQueueNewOutput(
            &vDataFormat,
            HandleAudioQueueOutputCallback,
            &m_PlayerContext,
            CFRunLoopGetMain(),
            CFRunLoopMode.commonModes.rawValue,
            0,
            &m_AudioQueue))
        
        //  Set volume.
        try audioQueueCallingAssert(AudioQueueSetParameter(
            m_AudioQueue, kAudioQueueParam_Volume, 1.0))
        
        //  Bind 'isrunning' event.
        try audioQueueCallingAssert(AudioQueueAddPropertyListener(
            m_AudioQueue,
            kAudioQueueProperty_IsRunning,
            HandleAudioQueueIsRunningCallback,
            &m_PlayerContext))
        
        //  Allocate buffer.
        let kNumberBuffers: UInt32 = UInt32(PACKET_NUMBER_PRE_BUFFER)
        m_BufferByteSize = kNumberBuffers * vDataFormat.mBytesPerPacket
        for _ in 0..<AUDIO_QUEUE_BUFFERS_COUNT {
            var buffer : AudioQueueBufferRef!
            
            //  Allocate buffer.
            try audioQueueCallingAssert(
                AudioQueueAllocateBuffer(
                    m_AudioQueue, m_BufferByteSize, &buffer))
            
            //  Enqueue buffer.
            m_PlayerContext.mAudioQueueBuffers.append(buffer)
            m_PlayerContext.mAudioQueueBuffersBusy.append(false)
        }
        
    }
    
    ///
    ///  Free player resource.
    ///
    private func freePlayer() {
        //  Clear buffer data after all audio data is played.
        for buffer in self.m_PlayerContext.mAudioQueueBuffers {
            AudioQueueFreeBuffer(self.m_AudioQueue, buffer)
        }
        self.m_PlayerContext.mAudioQueueBuffers.removeAll()
        self.m_PlayerContext.mAudioQueueBuffersBusy.removeAll()
        
        //  Clear audio queue pointer.
        self.m_AudioQueue = nil
    }
    
    ///
    ///  Write audio data to player.
    ///
    /// - Parameter data: The audio data.
    ///
    /// - Throws: Rasied in the following situation:
    ///
    ///             - There is no free space of audio queue.
    ///             - Enqueuing buffer into audio queue was failed.
    ///
    private func writeToPlayer(data: Data) throws {
        //  Find free space (position).
        var index: Int? = nil
        for i in 0..<m_PlayerContext.mAudioQueueBuffers.count {
            if !m_PlayerContext.mAudioQueueBuffersBusy[i] {
                index = i
                break
            }
        }
        guard let bufIndex = index else {
            throw XAPError(message: "No free audio queue buffer.")
        }
        
        //  Enqueue buffer.
        let buf = m_PlayerContext.mAudioQueueBuffers[bufIndex]
        buf.pointee.mAudioDataByteSize = UInt32(data.count)
        buf.pointee.mAudioData.advanced(by: 0).copyMemory(
            from: data.withUnsafeBytes{ $0.baseAddress! },
            byteCount: data.count)
        m_PlayerContext.mAudioQueueBuffers[bufIndex] = buf
        m_PlayerContext.mAudioQueueBuffersBusy[bufIndex] = true
        try audioQueueCallingAssert(
            AudioQueueEnqueueBuffer(m_AudioQueue, buf, 0, nil))
    }
    
    private func registerAudioQueueIsRunningEvent(handler:@escaping () -> Void){
        m_PlayerContext.mAudioQueueIsRunningHandler = {
            if self.m_Status == .closing {
                self.freePlayer()
                
                //  Switch status.
                self.m_Status = .closed
            }
            
            handler()
        }
    }
    
    //
    //  MARK: XAPPlayer public methods.
    //
    
    ///
    ///  Start to play.
    ///
    ///  - Throws: Raised in the following situation:
    ///
    ///             - Player is already running.
    ///             - Allocation was failed.
    ///
    public func start(dataFormat: AudioStreamBasicDescription) throws {
        //
        //  Lock.
        //
        g_AudioQueueLock.wait()
        defer {
            //
            //  Unlock.
            //
            g_AudioQueueLock.signal()
        }
        
        //  Check status.
        if m_Status != .wait {
            throw XAPError(message: "The player is already started.")
        }
                
        //  Allocate resource.
        try allocPlayer(dataFormat: dataFormat)
        
        //  Start player.
        try audioQueueCallingAssert(AudioQueueStart(m_AudioQueue, nil))
        
        //  Switch status.
        m_Status = .running
    }
    
    ///
    ///  Stop to play.
    ///
    ///  - Throws: Raised if player is not running.
    ///
    public func stop() throws {
        //
        //  Lock.
        //
        g_AudioQueueLock.wait()
        defer {
            //
            //  Unlock.
            //
            g_AudioQueueLock.signal()
        }
        
        //  Check status.
        if m_Status != .running {
            throw XAPError(message: "The player is not running.")
        }
        
        //  Stop audio queue.
        try audioQueueCallingAssert(AudioQueueStop(m_AudioQueue, false))
        
        //  Audio queue may not even acquired the data from some buffers at this
        //  time, so we clear buffer after finishing to play all the audio data.
        
        //  Change status.
        m_Status = .closing
    }
    
    ///
    ///  Write audio data to player.
    ///
    /// - Parameter data: The audio data.
    ///
    /// - Throws: Rasied in the following situation:
    ///
    ///             - Raised if player is not running.
    ///             - There is no free space of audio queue.
    ///             - Enqueuing buffer into audio queue was failed.
    ///
    public func write(data: Data) throws {
        //
        //  Lock.
        //
        g_AudioQueueLock.wait()
        defer {
            //
            //  Unlock.
            //
            g_AudioQueueLock.signal()
        }
        
        //  Check 'running' status.
        if m_Status != .running {
            throw XAPError(message: "The recorder is not running.")
        }
        
        //  Split audio data into blocks with a maximum size of each buffer.
        //  And write to audio queue.
        var cursor = 0
        while cursor < data.count {
            var len = data.count - cursor
            if len > Int(m_BufferByteSize) {
                len = Int(m_BufferByteSize)
            }
            let subData = data[cursor..<(cursor + len)]
            try writeToPlayer(data: subData)
            cursor += len
        }
    }
    
    ///
    ///  Register audio queue 'kAudioQueueProperty_IsRunning' event, which may occurred sometime
    ///  after 'start' or 'stop' function is called.
    ///
    ///  - Parameter handler: The handler.
    ///
    public func onAudioQueueIsRunningEvent(handler: @escaping () -> Void) {
        //
        //  Lock.
        //
        g_AudioQueueLock.wait()
        defer {
            //
            //  Unlock.
            //
            g_AudioQueueLock.signal()
        }
        
        //  Bind.
        m_PlayerContext.mAudioQueueIsRunningHandler = handler
    }
}
