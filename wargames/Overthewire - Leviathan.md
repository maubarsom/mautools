# Overthewire - Leviathan

**leviathan1**: rioGegei8m

Solution: grep for "pass" in the bookmarks file in the ./backup folder

**leviathan2**: ougahZi8Ta

Solution: 
The executable is setuid to leviathan2, and launches a shell when you guess it's password
When you hex dump the executable , find strange lines with the words "sex", "love", and "god", and try them all.
The password of the exec is sex
Then use the priviledged shell to dump the contents of /etc/leviathan_pass/leviathan2

**leviathan3**: Ahdiemoo1j
Solution: 
-> printfile is an executable with owner and setuid to leviathan3

-> Structure of the executable seems to be :

```
main( file ):
      if  ( sys_access( file , READ )  )     
                cat file   # with leviathan3 permissions
```

-> strace reveals "access" system call:  access queries if USER INVOKING (not the application) has permission to read the file. This behavior is deliberately done to regulate setuid executables
    -> In this context it means that printfile will only execute cat on files that can be read by leviathan2 as well
    -> but cat is executed with leviathan3 permissions

Solution: Fooling the sys_access with spaces!

Create a file called “file1 file2” .
Then because cat is directly concatenating the string, it will cat both file1 and file2 as separate files, so just creating a softlink :

`ln -s /etc/leviathan_pass/leviathan3 file1`

will let you print the pass

Hints:
False leads : Exploiting the IFS shell variable
https://www.pentestpartners.com/blog/exploiting-suid-executables/
http://www.thegeekstuff.com/2011/11/strace-examples/

**leviathan4**: vuH0coox6m

Correct solution:
Run ltrace ./level3 and check the strcmp T_T

Solution:
  -> Check level 3 symbols:

2 curious ones: `do_stuff` and `nothing`

do_stuff is the function where everything happens
nothing doesn’t appear in the executable :/ -> in the data section but I cannot manage to print it :/ the address is not visible with nm nor objdump

```
main structure:
  printf(“Enter the password>”)
  do_stuff()


do_stuff(){
    wtf = “snlprintf\\n”
    buf = fgets( password) 
    str_cmp(buf, wtf)
```

By running GDB in assembly mode

```gdb
> disa
> break do_stuff
# or actually more specifically
> break 0x080486ae, which is the address of the instruction right before the str_cmp
# then 
info locals prints out 
wtf = "snlprintf\\n"
```

Whatever is in register EAX when executing instruction in address `0x80485aa` : `mov    %eax,0x4(%esp)`

corresponds to the address where the password is stored. Where did that come from ? Possibly dynamically loaded into memory ? somewhere mmm

**leviathan5**: Tith4cokei

Solution; look for a hidden folder `.trash`
Run ./bin and see a string of bytes
Convert bytes to ascii -> password

**leviathan6**: UgaoFee4li

Solution: 
Create a softlink to /etc/leviathan_pass/leviathan5 in /tmp
run ./leviathan5

**leviathan7**: ahy7MaeBo9

Solution:
`for x in $(seq -f"%04.0f" 0 9999); do echo $x; ./leviathan6 $x ; done`