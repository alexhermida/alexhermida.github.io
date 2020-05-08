+++
title = "Scaling PostgreSQL from a developer point of view."

date = 2019-06-10
lastmod = 2019-06-10
draft = true

tags = ["PostgreSQL", "Databases"]
summary = "Scaling PostgreSQL from a developer point of view."

[header]
image = "postgresql_logo.svg"
caption = "Credit: [**PostgreSQL**](https://wiki.postgresql.org/wiki/Logo)"

+++

As a developer you have to deal with databases from time to time in your work-life, and if you are a web developer probably making queries it is something your are facing daily.
Since I'm not a database administrator nor an PostgreSQL expert I only want to give some small tips in case you are dealing with scaling issues or starting with PostgreSQL and you want to know more about some underlying processes.

Things you must take into account when you add a query to your code:

* Indexes
* Explain (planner)
* Vaccum

/timing
./restart_postgrescache

## Indexes

`CREATE INDEX`

Probably this is one of the things that every developer take care of when is trying to improve a query or implementing some complex one. Regardless
_indexes_ is one of most important things in a query plan it also can have counterparts.

* B-tree: Is the default option when you create an index and is recommended to handle equality, range queries using [basic comparison](https://www.postgresql.org/docs/current/functions-comparison.html). It also works well with sorted data.
* Hash: It can only handle equality comparisons although are [discouraged](https://www.postgresql.org/docs/7.2/indexes-types.html) because the need of reindex in case of database crash and there is no probe of performance improvements with B-tree. Although in PostgreSQL 10 is crash safe.
* GiST (Generalized Search Tree): Give us a complex system for implementing different strategies depending of the data types. Are good for geometric data types and full-text search. It has [built-in operator classes](https://www.postgresql.org/docs/current/gist-builtin-opclasses.html) although
you can extend it.
* SP-GiST (space-partitioned GiST): Similar to GiST s meat to allow development of custom data types but supports partitioned search trees for use
with unbalanced data structures.
* GIN (Generalized Inverted Index): Are good for dealing with composite values like array values or JSONB.
* BRIN (Block Range INdexes): For handling large datasets created sequentially. The index group adjacent datasets in the table with blocks. This allow to also save a lot of disk space because it keeps an index entry for the block itself instead of the tuple.

As you can see, some of the Indexes types , like GIN or GiST, are more worried about the knowledge of the data types rather than a database size or structure.

In general, the use of indexes is essential for good performance and it is something that you have to take care of as a developer. To implement it you must take into account:

* Lookups performed
* The data type
* Underlying data within the table

With this three variables you must decide what index you have to choose for improving your queries. How you can evaluate it in PostgreSQL? With `EXPLAIN`.


## Planner

Within the internal structure of PostgreSQL you can find the "Planner", which is in charge of looking for the best execution plan for a SQL query. In the [official documentation](https://www.postgresql.org/docs/9.5/planner-optimizer.html) there are pretty documentation regarding how the internals work. I only try to give some clues about how you can analyze a specific query.

After parse the query, PostgreSQL will try to:

1. Generate different execution plans
2. Calculate the cost of each plan
3. Select the best one to execute the query


Since you can't guess your query behavior _EXPLAIN_ will be your main tool.

`EXPLAIN` help you to view how the planner interprets queries and determines the optimal execution. Combining it with options like _ANALYZE, COSTS, or VERBOSE_ gives you the plan chosen by the planner. When you execute _EXPLAIN_ you get some result like:

```
$ EXPLAIN ANALYZE select * from test WHERE num=164;
                                                      QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..8325.47 rows=483 width=41) (actual time=10.448..260.448 rows=509 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on test  (cost=0.00..7277.17 rows=201 width=41) (actual time=5.214..236.655 rows=170 loops=3)
         Filter: (num = 164)
         Rows Removed by Filter: 166497
 Planning time: 6.670 ms
 Execution time: 263.254 ms
(8 rows)

Time: 327,272 ms

```

Using the keyword _ANALYZE_ you will have more detail but take care because the query will be executed!. For detail understanding of it you can go to the PosgreSQL [docs](https://www.postgresql.org/docs/9.5/using-explain.html). I will only give some little advice of some key points about it.

* Check the total cost and time. The upper-level node includes all children costs.
* Review what indexes are being used in every particular node.
* Review access methods for every node (Sequential Scan, Index Scan, Bitmap Heap Scan)
* Like in any programming language nest matters quite a lot.

For analysis you have some online tools:

* https://tatiyants.com/pev/
* https://explain.depesz.com

Or you can also use some local tool, even some IDE's like PyCharm/Intellij have the feature of showing the query plan as a diagram.


Additional information can be found at https://www.postgresql.org/docs/current/indexes-types.html
