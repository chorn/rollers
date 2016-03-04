# Solving the same problem

Back in the days of CVS, I wrote a program in Perl to do something nerdy. `roll.pl` generates sets of random dice based on a syntax derived from good old D&D. I must have been obsessed with it, because I used the same file as a CLI, an `irssi` script, and as a library for some weird CGI thing I must have forgotten about.

Since then, when I learn a new programming language, I usually rewrite this same problem in the new language. This tool, although small, has some complexity to it, and it's kind of mathy, which is something most languages are good at. The downside is that the first foray into a new language is usually terrible code.

## What does is do

```
$ roll.pl 1d20
1d20:  17
```

```
$ roll.rb 6x4D6r+1
4d6r+1:  3  + [2] +  4  +  6  = 13 + 1 = 14
4d6r+1: [2] +  3  +  5  +  4  = 12 + 1 = 13
4d6r+1:  6  +  6  + [3] +  3  = 15 + 1 = 16
4d6r+1:  6  +  4  + [2] +  3  = 13 + 1 = 14
4d6r+1:  4  +  3  +  4  + [2] = 11 + 1 = 12
4d6r+1:  4  +  5  + [2] +  4  = 13 + 1 = 14
```

* `6x` = 6 iterations
* `D` = drop the lowest score
* `r` =  re-roll ones
* `+1` = Add one to each score
