# Incrementer

This is a simple web service, which accepts requests to increment a value associated with a given key. The server synchronizes its state to a SQLite database every five seconds.

## Installation

Prerequisites:
- Elixir 1.4.5: `brew install elixir`
- SQLite 3.19.3: `brew install sqlite`

## Database Setup:
- The SQLite database is located in the root of the project and is named `./numbers.db`.
- In a fresh state, it contains the following:
```
CREATE TABLE numbers (key TEXT, value INTEGER DEFAULT 0);
CREATE UNIQUE INDEX numbers_key_index ON numbers (key);
```
- If needed, the database can be reset to a fresh state:
```
iex -S mix
Database.reset()
```

## Running the Server
1. `cd` into the `incrementer` directory and run `mix deps.get` to get the required dependencies.
2. Run `mix run --no-halt` to start the server which listens to port 3333

## API
There is a single endpoint at the `/increment` path, which responds to `POST` requests, accepting `key` and `value` parameters as follows:
```
curl -X POST http://localhost:3333/increment -d 'key=abcdef&value=1'
```
This will increment the `value` for the given `key` and will sync to the database about every 5 seconds.

## Load Testing
There are a number of tools that can be used for load testing. In developing this project, I used a tool called [siege](https://www.joedog.org/siege-home/), which can be used to test this web service under heavy load. I've included a file with 1000 randomly generated test urls in `./siege/urls.txt`, which I generated using a simple script, which can be found and modified in `./siege/url_gen.exs`. To simulate heavy load on the server, start the server and then run:
```
siege -f siege/urls.txt -c 200 -i -t 20S
```

This hits the urls in the file in a random order, simulating 200 concurrent users for 20 seconds. Feel free to modify this command as you like. In my testing, I've been getting results in the range of about 767 transactions per second:

```
Transactions:		       15350 hits
Availability:		      100.00 %
Elapsed time:		       20.00 secs
Data transferred:	        0.10 MB
Response time:		        0.01 secs
Transaction rate:	      767.50 trans/sec
Throughput:		        0.01 MB/sec
Concurrency:		        5.26
Successful transactions:       15350
Failed transactions:	           0
Longest transaction:	        0.13
Shortest transaction:	        0.00
```

## Approach and Design Strategy
I decided to try using Elixir for this project because I wanted it to perform well under heavy load, and concurrency seemed like it could be helpful for that goal. Also I just wanted to stretch myself and use it as an opportunity to learn and practice Elixir.

#### Concurrent Handling of Incoming Requests
Each incoming request is handled by separate GenServer processes, which handles the incrementing of the values, and holds onto the state of those values as they increment. Each process is registered with a name, where the name is the key. If a key already exists, then we use the process associated with that key. Otherwise, we spawn a new process. Using processes to handle incoming requests, allows us to better handle potentially many concurrent requests and provides a convenient and fast way of calculating and storing values in memory.

#### Caching
I use an Erlang Term Storage (ETS) table as a cache mechanism for fast in-memory writes of incoming data.


Then I use another GenServer process to implement a simple queue for background jobs. In this case, each background job is a SQL statement holding instructions for a bulk upsert of fresh data in the ETS table.



This was a really fun project, and I hope you enjoy!

## Dependencies
This project depends on the following hex packages:
- [Plug](https://github.com/elixir-lang/plug)
- [Cowboy](https://github.com/ninenines/cowboy)
- [Sqlitex](https://github.com/mmmries/sqlitex)
