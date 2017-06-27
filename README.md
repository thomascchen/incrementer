# Incrementer

This is a simple web service, which accepts requests to increment a value associated with a given key. The server synchronizes its state to a SQLite database roughly every five seconds.

## Installation

Prerequisites:
- Elixir 1.4.5: `brew install elixir`
- SQLite 3.19.3: `brew install sqlite`

## Database Setup
To create the database or to reset it to a fresh state, run:
```
mix run lib/database.exs --no-start
```

This creates a database named `./numbers.db` in the root of the project, that contains the following:
```
CREATE TABLE numbers (key TEXT, value INTEGER DEFAULT 0);
CREATE UNIQUE INDEX numbers_key_index ON numbers (key);
```

## Running the Server
1. `cd` into the `incrementer` directory and run `mix deps.get` to get the required dependencies.
2. Run `mix run --no-halt` to start the server which listens to port 3333

## API
There is a single endpoint at the `/increment` path, which responds to `POST` requests, accepting `key` and `value` parameters as follows:
```
curl -X POST http://localhost:3333/increment -d 'key=abcdef&value=1'
```
This will increment the `value` for the given `key` by calculating the sum of
the `value` parameter and all previously submitted values associated with
this `key`. The server will sync to the database about every 5 seconds.

## Tests
Run `mix test` to run the tests for the project.

## Load Testing
I used a tool called [siege](https://www.joedog.org/siege-home/) for load testing this project in development. I've included a file with 1000 randomly generated test urls in `./siege/urls.txt`, which I generated using a simple script, which can be found and modified in `./siege/url_gen.exs`. To simulate heavy load on the server, start the server and then run:
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

## Design Strategy
I decided to use Elixir for this project because I wanted it to perform well under heavy load, and concurrency seemed like it could be helpful for that goal. Also I wanted to stretch myself and use this as an opportunity to learn and practice Elixir.

The high level summary is that GenServer processes process incoming data and write this data to a shared ETS table. We defer database persistence to a periodic SQL statement that bulk upserts in-memory data from the ETS table to the database every 5 seconds. We also use the `Sqlitex.Server` GenServer module to keep the database open for the lifetime of the project, thereby preventing the need to open and close many database connections, which provides some additional performance benefits.

#### Concurrent Handling of Incoming Requests
Each incoming request is handled by separate GenServer processes, which increment the values, keep the state of those values as they change over time, and write those key-value pairs to an ETS table. Each process is registered with a name, where the name is the key. If a key already exists, then we use the process associated with that key. Otherwise, we spawn a new process. Using processes to handle incoming requests allows us to handle requests concurrently and provide a convenient and fast way of calculating and storing values in memory.

#### Caching
An Erlang Term Storage (ETS) table serves as a cache mechanism for fast in-memory writes of incoming data to a central key-value store. The ETS table is created as a named, public table, so that all processes can concurrently write to that table.

#### Background Job queue
I use another GenServer to manage a simple queue for background jobs. In this case, each background job is a SQL statement holding instructions for a bulk upsert of fresh data in the ETS table. Every 5 seconds, we go through the following steps:
1. Construct an "INSERT OR REPLACE" statement containing all of the values in the ETS table and add that to the queue.
2. Execute the oldest statement in the queue to write the data to the database.
3. Delete stale entries from the ETS table (any object more than 1 second old). We do this to prevent the table from growing too larger and creating increasingly large upsert statements that could cause performance degradation. Thus the ETS table is holding only fresh data written in the most recent 5 seconds or so.

Realistically, we could almost certainly get away without background jobs (which is what I did in an earlier implementation), but depending on how much data is being processed, a potentially long running database write could lead to slowdowns that a queue would help alleviate. This is definitely premature optimization, but then again this is not a real world application, and it's an interesting exercise. 🙂 This was a really fun project, and I hope you enjoy!


## Dependencies
This project depends on the following hex packages:
- [Plug](https://github.com/elixir-lang/plug)
- [Cowboy](https://github.com/ninenines/cowboy)
- [Sqlitex](https://github.com/mmmries/sqlitex)
