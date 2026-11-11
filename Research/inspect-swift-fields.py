from pathlib import Path
import struct,sys,json
b=Path(sys.argv[1]).read_bytes();segments=[];sections=[];p=32
for _ in range(struct.unpack_from('<I',b,16)[0]):
 cmd,size=struct.unpack_from('<II',b,p)
 if cmd==25:
  name=b[p+8:p+24].split(b'\0')[0].decode();a,v,o,n=struct.unpack_from('<QQQQ',b,p+24);segments.append((a,a+n,o))
  for j in range(struct.unpack_from('<I',b,p+64)[0]):
   q=p+72+80*j;na=b[q:q+16].split(b'\0')[0].decode();va,z,off=struct.unpack_from('<QQI',b,q+32);sections.append((na,va,z,off))
 p+=size

def read(a,n):
 for lo,hi,o in segments:
  if lo<=a and a+n<=hi:return b[o+a-lo:o+a-lo+n]
 raise ValueError(hex(a))
def i32(a):return struct.unpack('<i',read(a,4))[0]
def text(a):return read(a, min(300,next(hi-a for lo,hi,o in segments if lo<=a<hi))).split(b'\0')[0].decode(errors='replace')
def rel(a):return a+i32(a)
def typename(a):
 try:
  raw=read(a,1)
  if raw==b'\x01':
   context=a+1+i32(a+1);return text(rel(context+8))
  return text(a)
 except:return '?'+hex(a)
sec=next(s for s in sections if s[0]=='__swift5_fieldmd');a=sec[1];end=a+sec[2];out=[]
while a+16<=end:
 ty,sup,kind,size,count=struct.unpack('<iiHHI',read(a,16))
 if not size or size<12 or count>1000:break
 name=typename(a+ty) if ty else '?'
 fields=[]
 for j in range(count):
  q=a+16+j*size;flags,t,n=struct.unpack('<Iii',read(q,12));fields.append({'name':text(q+8+n) if n else '?','type':typename(q+4+t) if t else '?'})
 if any(s.lower() in name.lower() for s in sys.argv[2:]):out.append({'name':name,'kind':kind,'fields':fields})
 a+=16+size*count
print(json.dumps(out,ensure_ascii=False,indent=2))
