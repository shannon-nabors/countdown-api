# Countdown Numbers API

This API is modeled off of the "numbers round" of the British game show Countdown.  Written in Ruby and hosted with Sinatra.

## How does the numbers round work?
On the show, the contestants are shown six number tiles, chosen from among the "big" numbers (100, 75, 50, 25) and the "little" numbers (1 through 10).  There is one of each of the big numbers and two of each little number, so you might get two 3s, but you would never get two 75s or three 3s.

Contestants say how many "big" numbers and "little" numbers they want.  For example, if you requested 3 big numbers and 3 little numbers, you might get 100, 25, 50, 5, 5 and 2.

A number between 101 and 999 is then given, and the contestants must use arithmetic to combine the six smaller numbers (they don't have to use all of them) to reach the target.

The rules are (as per the Countdown wikipedia page):
- Contestants may use only the four basic operations of addition, subtraction, multiplication and division
- A number may not be used more times than it appears on the board
- Division can only be performed if the result has no remainder (i.e., the divisor is a factor of the numerator)
- Fractions are not allowed, and only positive integers may be obtained as a result at any stage of the calculation

For example, if the target were 812 and the numbers were 75, 50, 2, 3, 8, and 7, a possible solution would be:

50 + 8 = 58

7 × 2 × 58 = 812

The API would return this as ```"7*2*(50+8)"``` (as well as ```"(50+8)*2*7"``` and ```"(50+8)*7*2"```, etc.)

## Endpoints
There is one endpoint, ```api/v1/solve```. Get requests to this endpoint can include two types of parameters:

- As on the show, you can make a request for six unknown numbers by specifying how many "big" numbers and how many "little" numbers you want.  This option will also generate a target number.
- If you know the target and the numbers (i.e. if you want to see how you can get 812 from 75, 50, 2, 3, 8 and 7), you can make a request for all the solutions.

## Installation and Use
Not yet deployed, but you can run it locally using the instructions below.  To get solutions, make a post request to the ```api/v1/solve``` endpoint including either the number of big/little numbers you want or the target/numbers.

```sh
git clone git@github.com:shannon-nabors/countdown-api.git
```

Inside the directory:
```sh
bundle
ruby server.rb
```

Sample request (with big/little specifications):
```sh
fetch('http://localhost:4567/api/v1/solve?big=4&little=2')
    .then(r => r.json()).then(console.log)
```
Response:
```sh
==> {target: 561, numbers: [100, 75, 50, 25, 4, 1], solutions: ["((100+75)/(25)+4)*(50+1)", "(100*4-25-1)*75/50", "(100*4-1-25)*75/50", "(100*4-(25+1))*75/50"... etc]}
```

Sample request (with target and numbers):
```sh
fetch('http://localhost:4567/api/v1/solve?target=812&numbers=75,50,8,7,3,2')
    .then(r => r.json()).then(console.log)
```
Response:
```sh
==> {target: 812, numbers: [75, 50, 8, 7, 3, 2], solutions: ["((75+50+8)*3+7)*2", "(75+50-8-3+2)*7", "(75+50-8+2-3)*7", "(75+50-8-(3-2))*7"... etc]}
```