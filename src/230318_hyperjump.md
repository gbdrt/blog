---
title: "Solving Quanta Magazine Hyperjump with Prolog"
author: "Guillaume Baudart"
date: "2023-03-18"
---

I recently came accross [Hyperjump](https://hyperjumps.quantamagazine.org) -- a new online game by [Quanta Magazine](https://www.quantamagazine.org/) -- and had a lot of fun playing this game.

The goal is to order a set of digits into a sequence that follows simple arithmetic rules.

- The first 2 digits can be anything
- A digit is valid if it can be obtained from the previous 2 with simple operations (+, -, *, /), only keeping the last digit.

\begin{array}{l@{}c@{}l@{}c@{}l}
    (X_{n-2} &+& X_{n-1}) \mod 10 &=& X_{n}\\
    (X_{n-2} &-& X_{n-1}) \mod 10 &=& X_{n} \quad \text{if $X_{n-2} - X_{n-1} > 0$}\\
    (X_{n-2} &*& X_{n-1}) \mod 10 &=& X_{n} \\
    (X_{n-2} &/& X_{n-1}) \mod 10 &=& X_{n} \quad \text{if $X_{n-2} / X_{n-1} \in \mathbb{N}$}\\
\end{array}

- The last digit is always 9.

The game is to find sequences of increasing length from the same set of 8 digits.
Everyday you get a new set, and you need to find 4 5-digits sequences, 3 6-digits sequences, 2 7-digits sequence, and as many 8-digits sequences as you can.
Each new sequence gets you 1 point.^[Reaching 10 points at the first complete 8-digits sequence.] 

While discussing this game at a coffee break, one colleague immediately said: *That sounds like something that could be done in Prolog.*
And indeed, 20mn later, he had a working solution for the puzzle of the day, and I really wanted to try as well.

Prolog is a logic programming language where a program is a set of relations between variables and a computation is a query over these relations.
One popular exercise is use Prolog to solve logical puzzles: sudoku, n-queens, ...
The rules are encoded by a set of relations and a typical query is: *Please Prolog, find a solution given these rules*.


# Encoding the rules

The first thing to do is to encode the rules with relations between 3 digits:^[We use the `is` operator for arithmetic relation, e.g., `A is 2 + 7` is the simple relation $A = 2 + 7$.] $X_{n}$, $X_{n-1}$, and $X_{n-2}$. 
   
```prolog
valid(X1, X2, X3) :- X3 is mod((X1 + X2), 10).
valid(X1, X2, X3) :- X3 is mod((X1 - X2), 10), (X1 - X2) > 0.
valid(X1, X2, X3) :- X3 is mod((X1 * X2), 10).
valid(X1, X2, X3) :- X3 is mod((X1 // X2), 10), 0 is mod(X1, X2).
```

Now, we need a relation that captures the fact that we pick digits from a set.
This is a classic Prolog relation `pick(L, X, R)` where `L` is the initial list, `X` is the chosen element, and `R` is the resulting list (`L` without `X`).^[`[X | T]` is the Prolog syntax for a list whose head element is `X` and `T` is the tail of the list.]
In Prolog we can program the relation `pick` with 2 cases: chose the head of the list, or choose an element in the tail.

```prolog
pick([X | R], X, R).
pick([X | T], E, [X | R]) :- pick(T, E, R).
```

# Version 1: Start from the end

For my first attempt, I tried mimicking what I was doing by hand to solve the puzzle, that is, start from the end (digit 9) and build the sequence in reverse order.

This behavior can be captured with a recursive relation `hyperjump(P, N, S)` where `P` is the set of digits and `S` is a valid sequence with `N+1` digits where the last digit is 9.

Starting from the final 9, the only constraint for the first digit `X` is to be in `P`.


```prolog
hyperjump(P, 1, [X, 9]) :- pick(P, X, _).
```

To add a digit `X1` at the beginning of the sequence, we choose `X1` from `P`, we check that the beginning of the sequence is valid,^[For some reason, we cannot use `N-1` directly for the recursive call and need to bind a new variable `M` with a simple relation `M is N - 1`.] and we check that the last 3 digits validate the rules.

```prolog
hyperjump(P, N, [X1, X2, X3 | R]) :-
  pick(P, X1, P1),
  M is N - 1,
  hyperjump(P1, M, [X2, X3 | R]),
  valid(X1, X2, X3).
```

Finally, we can ask Prolog to list all the solutions using `findall` and remove duplicates with `sort`.

```prolog
solutions(P, N, X) :- 
    findall(S, hyperjump(P, N, S), L),
    sort(L, X).
```

In the Prolog interpreter the following query then computes all the solutions:

```prolog
?- solutions([1,8,1,8,7,4,3,7], 8, S).
S = [[1, 7, 7, 4, 3, 8, 1, 8|...], ...]
```

Adding a pretty printer:

```prolog
?- print_solutions([1,8,1,8,7,4,3,7], 8).
1, 7, 7, 4, 3, 8, 1, 8, 9 
1, 8, 8, 1, 7, 4, 3, 7, 9 
3, 4, 7, 7, 1, 8, 8, 1, 9 
7, 1, 7, 4, 3, 8, 1, 8, 9
...
```

I tried this on the 03/15/2023 puzzle and it worked great, reaching a score of 11.
Next morning I tried again... and failed with a top score of 6.
Prolog only found 2 sequences of length 6 instead of the required 3.

```prolog
?- print_solutions([4, 4, 7, 3, 1, 1, 8, 5], 8).
1, 3, 4, 7, 1, 8, 9
7, 4, 3, 1, 4, 5, 9 
true.
```

# The missing rule

What happened is that I missed one important rule.

- For subtraction or division, if the operation is not directly possible, we can first combine previous digits into a multi-digits number.
For instance, `7 1 8 3` is valid because $71 - 8 = 63$, and  `8 3 4 9` is valid because $83 - 4 = 79$.
More generally:

$$
\begin{array}{l@{}c@{}l@{}c@{}l}
    (\sum_{i=0}^p 10^i X_{n-2-i} &-& X_{n-1}) \mod 10 &=& X_{n} \quad \text{for $p < n-2$}\\
    (\sum_{i=0}^p 10^i X_{n-2-i} &/& X_{n-1}) \mod 10 &=& X_{n} \quad \text{for $p < n-2$}\\
\end{array}
$$

Let's add this missing rule to our program.

First we need to convert a list of digits to a decimal number.
This is very easy if the list is in reversed order.

```prolog
decimal([X], N) :- N is X.
decimal([X | R], N) :-
    decimal(R, M),
    N is 10 * M + X.
```

We can now add a relation `combo(L, X2, X3)` to capture the new rule.
For the subtraction, at worst we need to combine 2 digits,^[For instance, $(223 - 4) \mod 10 = (23 - 4) \mod 10 = 9$.] combining 3 or more digits would yield the same result.

```prolog
combo([A2, A1], X2, X3) :-
    decimal([A2, A1], M),
    X3 is mod((M - X2), 10),
    (M - X2) > 0.
```

The division is more tricky, combos of arbitrary sizes can yield different digits.
^[`1 4 4 8 8 1 9` is valid because $144 / 8 = 18$.]
There is no reason to stop at 2-digits combos.
We thus extend the `combo` relation for divisions with lists of arbitrary size.

```prolog
combo(L, X2, X3) :-
    decimal(L, M),
    X3 is mod((M // X2), 10), 0 is mod(M, X2).
```

Now, there is a bigger problem.
We need to read the sequence from the start to test possible combos, but our first solution build the sequence from the end.^[It may be possible to adapt this solution with the `combo` rules, but after several attempts, I wanted to try something else.] 

# Version 2: Fill and check

Let's try another approach.
Instead of building a valid sequence from the end, we can generate valid sequences from the beginning and select only sequences that end with 9.

The first relation `fill(P, N, S)` return a valid sequence of size `N` from the set of digits `P`.
The first two digits can be anything in `P`.

```prolog
fill(P, 2, [X1, X2]) :-
    pick(P, X1, P1),
    pick(P1, X2, _).
```

To build a sequence of size `N`, we choose the last digit `X3`, we build the beginning of the sequence with the rest of the digits, and check that the last 3 digits validate the rules.
Note that the sequence is returned in reverse order. 
The base case is a list with 2 elements, and we add elements one by one at the head.

```prolog
fill(P, N, [X3, X2, X1 | R]) :-
    M is N - 1,
    pick(P, X3, P3),           
    fill(P3, M, [X2, X1 | R]),
    valid(X1, X2, X3).
```

We now need to add the missing rule to this relation.
We can use the `append(A, B, S)` relation to test the `combo` rules^[Since the sequence is already in reverse order, we can directly apply the `decimal` rule in `combo`.] with an arbitrary prefix `A` of `S`.


```prolog
fill(P, N, [X4, X3, X2, X1 | R]) :-
    M is N - 1,
    pick(P, X4, P4),
    fill(P4, M, [X3, X2, X1 | R]),
    append([A2, A1 | AR], _, [X2, X1 | R]),
    combo([A2, A1 | AR], X3, X4).
```

Finally, the `hyperjump` relation reject sequences that do not end with 9, and reverse the solution for readability.

```prolog
hyperjump(P, N, R) :-
    M is N + 1,
    fill([9 | P], M, [9 | S]),
    reverse([9 | S], R).
```

With this approach I was finally able to reach the last level of every puzzle with scores ranging from 14 to a record of 19. 

------------------------------------
