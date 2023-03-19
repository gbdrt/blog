%%% Hyperjump (Quanta Magazine Game)
%%% https://hyperjumps.quantamagazine.org/

% Run with `swipl hyperjump.pl`
% then `?- print_solutions([1,8,1,8,7,4,3,7], 8).`
% reload program with `?- [hyperjump].`

%% Encoding the rules

valid(X1, X2, X3) :- X3 is mod((X1 + X2), 10).
valid(X1, X2, X3) :- X3 is mod((X1 - X2), 10), (X1 - X2) > 0.
valid(X1, X2, X3) :- X3 is mod((X1 * X2), 10).
valid(X1, X2, X3) :- X3 is mod((X1 // X2), 10), 0 is mod(X1, X2).

% pick(L, X, R): pick X in L where R is the resulting list
pick([X | R], X, R).
pick([X | T], E, [X | R]) :- pick(T, E, R).


%%% Version 1: Start from the end
%% Build increasing sequence starting from the last 9.

% hyperjump(P, 1, [X, 9]) :- pick(P, X, _). % last element must be in the planets

% hyperjump(P, N, [X1, X2, X3 | R]) :-
%   pick(P, X1, P1),                % choose a new planet
%   M is N - 1,
%   hyperjump(P1, M, [X2, X3 | R]), % validate from X2 with remaining planets
%   valid(X1, X2, X3).              % test last 3 planets.  

%% Problem: Does not work with 4 numbers combos.
%% Example: [4, 4, 7, 3, 1, 1, 8, 5] (03/14/23) is stuck with only 2 6-jumps...


%% Missing rule

% Convert a reversed list of digits to a number (base 10)
decimal([X], N) :- N is X.
decimal([X | R], N) :-
    decimal(R, M),
    N is 10 * M + X.

% Combine 2 digits for substraction
combo([A2, A1], X2, X3) :-
    decimal([A2, A1], M),
    X3 is mod((M - X2), 10),
    (M - X2) > 0.

% Combine arbitrary number of digits for division
combo(L, X2, X3) :-
    decimal(L, M),
    X3 is mod((M // X2), 10), 0 is mod(M, X2).


%%% Version 2: Fill and check
%% Generate only valid sequence and then check that the last planet is 9.

fill(P, 2, [X1, X2]) :- % first 2 planets can be anything
    pick(P, X1, P1),
    pick(P1, X2, _).

fill(P, N, [X3, X2, X1 | R]) :-
    M is N - 1,
    pick(P, X3, P3),           % choose a planet
    fill(P3, M, [X2, X1 | R]), % build the rest of the sequence
    valid(X1, X2, X3).         % test last 3 planets

fill(P, N, [X4, X3, X2, X1 | R]) :-
    M is N - 1,
    pick(P, X4, P4),                        % choose a planet
    fill(P4, M, [X3, X2, X1 | R]),          % build the rest of the sequence
    append([A2, A1 | AR], _, [X2, X1 | R]), % split somewhere for combo
    combo([A2, A1 | AR], X3, X4).           % test combo

hyperjump(P, N, R) :-
    M is N + 1,
    fill([9 | P], M, [9 | S]), % fill a random sequence, force 9 at the end
    reverse([9 | S], R).       % reverse for readability


%% Print solutions 

solutions(P, N, X) :- 
    findall(S, hyperjump(P, N, S), L), % list all solutions
    sort(L, X).                        % sort remove duplicate (lex order)

% Print a list of integers
print_one([]).
print_one([X | R]) :-
    format('~d, ', X),
    print_one(R).

% Print a list of list of integers
print_all([]).
print_all([X | R]) :-
    print_one(X),
    format('~n'),
    print_all(R).

% Compute and print solutions
print_solutions(P, N) :-
    solutions(P, N, X),
    print_all(X).