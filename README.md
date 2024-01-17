The program converts given numbers throughout the file to respective forms in words, e.g. 10 turns to onezero.

To RUN the program, [TASM](https://klevas.mif.vu.lt/~linas1/KompArch/TASM.zip) & [DosBox](https://sourceforge.net/projects/dosbox/) are required.

To LAUNCH and use the program:
1) Put the project file inside TASM's installation folder, as well as data (input) file.
2) Start up DosBox.
3) Enter these commands in this exact sequence:
```
mount c: *tasm installation folder's location* (for example, mount c: d:/tasm)
c:
tasm NoToStr.asm
tlink NoToStr.obj
NoToStr.exe *data file name* *results file name* (for example, NoToStr.exe data.txt res.txt)
```
If the User does not understand how to proceed, they can input just the name of the program or it followed by '/?' in order to get a further explanation.

Data file can contain various numbers or symbols. Only the numbers present in the file will be affected. For example, data file such as

```
2021
12
01

I am testing some symbols.

0
1
2
3
4
5
6
7
8
9
```
turns into
```
twozerotwoone
onetwo
zeroone

I am testing some symbols.

zero
one
two
three
four
five
six
seven
eight
nine
```
