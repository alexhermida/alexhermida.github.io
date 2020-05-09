+++
title = "Scaling PostgreSQL from a developer point of view."

date = 2019-06-10
draft = false

categories = [
    "databases",
]
tags = ["PostgreSQL", "data"]

[header]
image = "postgresql_logo.svg"
caption = "Credit: [**PostgreSQL**](https://wiki.postgresql.org/wiki/Logo)"

+++

As a developer, you have to deal with databases from time to time in your work-life, and if you are a web developer probably making queries, it is something you are facing daily.
<!--more-->
Since I'm not a database administrator nor a PostgreSQL expert I only want to give some small tips if you are dealing with scaling issues or starting with PostgreSQL and you want to know more about some underlying processes.

Things you must take into account when you add a query to your code:

* Indexes
* Explain (planner)
* Vaccum

## Indexes

`CREATE INDEX`

Probably this is one of the things that every developer take care of when is trying to improve a query or implementing some complex one. Regardless
_indexes_ is one of the most important things in a query plan; it also can have counterparts.

* B-tree: Is the default option when you create an index and is recommended to handle equality, range queries using [basic comparison](https://www.postgresql.org/docs/current/functions-comparison.html). It also works well with sorted data.
* Hash: It can only handle equality comparisons although they are [discouraged](https://www.postgresql.org/docs/7.2/indexes-types.html) because the need of reindexing in case of database crash and there is no probe of performance improvements with B-tree. Although PostgreSQL 10 is crash-safe.
* GiST (Generalized Search Tree): Give us a complex system for implementing different strategies depending on the data types. Are good for geometric data types and full-text search. It has [built-in operator classes](https://www.postgresql.org/docs/current/gist-builtin-opclasses.html) although
you can extend it.
* SP-GiST (space-partitioned GiST): Similar to GiST s meat to allow the development of custom data types but supports partitioned search trees for use with unbalanced data structures.
* GIN (Generalized Inverted Index): Are suitable for dealing with composite values like array values or JSONB.
* BRIN (Block Range INdexes): For handling large datasets created sequentially. The index group adjacent datasets in the table with blocks. This type allows also to save a lot of disk space because it keeps an index entry for the block itself instead of the tuple.

As you can see, some of the Indexes types, like GIN or GiST, are more worried about the knowledge of the data types rather than a database size or structure.

In general, the use of indexes is essential for excellent performance, and it is something that you have to take care of as a developer. To implement it, you must take into account:

* Lookups performed
* The data type
* Underlying data within the table

With these three variables, you must decide what index you have to choose for improving your queries. How can you evaluate it in PostgreSQL? With `EXPLAIN`.

## Planner

Within the internal structure of PostgreSQL, you can find the "Planner", which is in charge of looking for the best execution plan for a SQL query. In the [official documentation](https://www.postgresql.org/docs/9.5/planner-optimizer.html) there is much documentation regarding how the internals work. I only try to give some clues about how you can analyze a specific query.

After parsing the query, PostgreSQL will try to:

1. Generate different execution plans
2. Calculate the cost of each plan
3. Select the best one to execute the query


Since you can't guess your query behaviour _EXPLAIN_ will be your main tool.

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

Using the keyword _ANALYZE_ you will have more detail but take care because the query will be executed!. For detail understanding of it you can go to the PosgreSQL [docs](https://www.postgresql.org/docs/9.5/using-explain.html). I will only give some little advice about some key points.

* Check the total cost and time. The upper-level node includes all children costs.
* Review what indexes are being used in every particular node.
* Review access methods for every node (Sequential Scan, Index Scan, Bitmap Heap Scan)
* Like in any programming language nest matters quite a lot.

For analysis, you have some online tools:

* https://tatiyants.com/pev/
* https://explain.depesz.com

Or you can also use some local tool, even some IDE's like PyCharm/Intellij has the feature of showing the query plan as a diagram.

You can find additional information at https://www.postgresql.org/docs/current/indexes-types.html

## Vaccum

Vaccum can be another key feature when you are scaling up. The Vaccum primary job is to reclaim storage space occupied by dead tuples so it can be available to be re-used by future data insertion within the same table.
I think that the latest versions of PostgreSQL do a good job on this, and if you have the autovacuum active it works very well. Although you can tweak the configuration if it's necessary, I would say if you are developer and not PostgreSQL expert, keep away of doing it.

Nevertheless, you always have the possibility of executing the process manually in specific cases. Vaccum can run in two different ways in PostgreSQL.

1. Plain Vaccum

When you run the `VACCUM` statement, reclaimed storage space is not given back to the operating system rather they are just defragmented within the same page but there is no exclusive lock and can run in parallel with normal read and writing.

1. Full Vaccum

`VACCUM FULL` return the disk space to the operating system but creates an exclusive lock on each table while it is being processed.

I hope these brief notes can give you a better understanding of what it's behind the scenes.

Cheers!
