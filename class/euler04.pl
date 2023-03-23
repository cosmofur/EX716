maxv=0
for i in range(999,100,-1):
    for j in range(999,100,-1):
        v=i*j
        if ( v > maxv):
            s=str(v)
            testflag=True
            for jj in range(0,int(len(s)/2)):
                if s[jj] != s[len(s)-1-j]:
                    testflag=False
                    break
            if testflag:
                print(s)
                if v>maxv:
                    maxv=v
print("Max  %d" % maxv)
