
import("stdfaust.lib");

//declare soundfiles "https://raw.githubusercontent.com/sletz/faust-sampler/main";

//process = 0,_~+(1):soundfile("son[url:{'violon.wav'}]",2):!,!,_,_;

process = 0,_~+(1):soundfile("son[url:{'tests/wav/amen.wav'}]",2):!,!,_,_;
