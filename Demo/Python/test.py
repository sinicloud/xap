import json
import sys

def test() -> [str]:
    a = []
    a.append("a")
    a.append(1)
    return a


print(test())