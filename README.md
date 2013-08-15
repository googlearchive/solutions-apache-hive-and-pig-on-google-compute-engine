Apache Hive and Pig on Google Compute Engine
============================================

Copyright
---------

Copyright 2013 Google Inc. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


Disclaimer
----------

This sample application is not an official Google product.


Summary
-------

This sample application can be used to install Apache
Hive or Pig on top of a running installation of a
Hadoop cluster on Google Compute Engine.

Prerequisites
-------------

This sample application assumes that one has already brought up
a Hadoop cluster on Google Compute Engine with
[solutions-google-compute-engine-cluster-for-hadoop](https://github.com/GoogleCloudPlatform/solutions-google-compute-engine-cluster-for-hadoop).

One should place this sample application in a separate directory
from `solutions-google-compute-engine-cluster-for-hadoop`.

In addition to a running Google Compute Engine cluster, the sample
requires the user running the installation scripts and the Google
Compute Engine instances to have authorized access to a Google
Cloud Storage bucket.
You may use the same bucket as the one used when starting the cluster.

Package Downloads
-----------------

This sample application can be used to install just one or both
of the packages discussed here.
Which packages are installed will be driven simply by copying the respective
tool's package archive into the "packages/_toolname_" subdirectory
prior to running the installation scripts.

### Hive Package Setup
Create a directory for the Hive package:

    mkdir -p packages/hive

Download Hive from
[hive.apache.org](http://hive.apache.org/releases.html)
and copy the gzipped tar file
into the `packages/hive/` subdirectory.  Testing of this sample application
was performed with `hive-0.10.0.tar.gz`.

### Pig Package Setup
Create a directory for the Pig package:

    mkdir -p packages/pig

Download Pig from
[pig.apache.org](http://pig.apache.org/releases.html)
and copy the gzipped tar file
into the `packages/pig/` subdirectory.  Testing of this sample application
was performed with pig-0.11.1.tar.gz.

If installing both tools, the packages subdirectory will
now appear as:

    packages/
      hive/
        hive-0.10.0.tar.gz
      pig/
        pig-0.11.1.tar.gz

Enter project details into properties file
------------------------------------------
Edit the file `project_properties.sh` found in the root directory of the
sample application.

Update the `GCS_PACKAGE_BUCKET` value with the bucket name of the Google
Cloud Storage associated with your Hadoop project, such as

    readonly GCS_PACKAGE_BUCKET=myproject-bucket

Update the `ZONE` value with the Compute Engine zone associated with your
Hadoop master instance, such as:

    readonly ZONE=us-central2-a

Update the `MASTER` value with the name of the Compute Engine
Hadoop master instance associated with your project, such as:

    readonly MASTER=myproject-hm

The sample application will create a system userid named `hdpuser` on the
Hadoop master instance.  The software will be installed into the user's
home directory `/home/hdpuser`.

If you would like to use a different username or install the software
into a different directory, then update the `HDP_USER`, `HDP_USER_HOME`,
and `MASTER_INSTALL_DIR` values in `project_proerties.sh`.

Push packages to cloud storage
------------------------------
From the root directory where this sample application has been installed,
run:

    $ ./scripts/packages-to-gcs__at__host.sh

This command will push the packages tree structure up to the
`GCS_PACKAGE_BUCKET` configured above.

Run installation onto Hadoop master
-----------------------------------
From the root directory where this sample application has been installed,
run:

    $ ./scripts/install-packages-on-master__at__host.sh

This command will perform the installation onto the Hadoop master instance,
including the following operations:

  * Create the `hdpuser`
  * Install software packages
  * Set user privileges in the Google Compute Engine instance filesystem
  * Set user privileges in the Hadoop File System (HDFS)
  * Set up SSH keys for the `hdpuser`

Tests
-----
On successful installation, the script will emit the appropriate command
to connect to the `hdpuser` over SSH.

Once connected to the Hadoop master, the following steps will help verify
a functioning installation.

The examples here use the `/etc/passwd` file, which contains no actual
passwords and is publicly readable.

### Hive Test
On the Hadoop master instance, under the `hdpuser` copy the
`/etc/passwd` file from the file system into HDFS:

    $ hadoop fs -put /etc/passwd /tmp

Start the Hive shell with the following command:

    $ hive

At the Hive shell prompt enter:

    CREATE TABLE passwd (
      user STRING,
      dummy STRING,
      uid INT,
      gid INT,
      name STRING,
      home STRING,
      shell STRING
    )
    ROW FORMAT DELIMITED
        FIELDS TERMINATED BY ':'
    STORED AS TEXTFILE;

    LOAD DATA INPATH '/tmp/passwd'
    OVERWRITE INTO TABLE passwd;

    SELECT shell, COUNT(*) shell_count
    FROM passwd
    GROUP BY shell
    ORDER BY shell_count DESC;

This should start a MapReduce job sequence to first group and sum
the shell types and secondly to sort the results.

The query results will be emitted to the console and should look
something like:

    /bin/bash 23
    /usr/sbin/nologin 21
    /bin/sync 1

To drop the table enter:

    DROP TABLE passwd;

Note that you do NOT need to remove the passwd file from HDFS.
The LOAD DATA command will have _moved_ the file from `/tmp/passwd`
to `/user/hdpuser/warehouse`.  Dropping the `passwd` table will
remove the file from `/user/hdpuser/warehouse`.

To exit the Hive shell enter:

    exit;

### Pig Test
On the Hadoop master instance, under the `hdpuser` copy the
`/etc/passwd` file from the file system into HDFS:

    $ hadoop fs -put /etc/passwd /tmp

Start the Pig shell with the following command:

    $ pig

At the Pig shell prompt enter:

    data = LOAD '/tmp/passwd'
           USING PigStorage(':')
           AS (user:CHARARRAY, dummy:CHARARRAY, uid:INT, gid:INT,
               name:CHARARRAY, home:CHARARRAY, shell:CHARARRAY);
    grp = GROUP data BY (shell);
    counts = FOREACH grp GENERATE
             FLATTEN(group), COUNT(data) AS shell_count:LONG;
    res = ORDER counts BY shell_count DESC;
    DUMP res;

This should start a MapReduce job sequence to first group and sum
the shell types, secondly to sample the results for the subsequent
sort job.

The query results will be emitted to the console and should look
something like:

    (/bin/bash,23)
    (/usr/sbin/nologin,21)
    (/bin/sync,1)

To exit the Pig shell enter:

    quit;

When tests are completed, the passwd file can be removed with:

    $ hadoop fs -rm /tmp/passwd

Appendix A
----------
Using MySQL for the Hive Metastore

The default Hive installation uses a local Derby database to store the table
and column meta information (table and column names, column types, etc).
This local database is fine for single-user/single-session usage, but a common
setup is to configure Hive to use a MySQL database instance.

The following sections describe how to setup Hive to use a MySQL database
either using Google Cloud SQL or a self-installed and managed MySQL database
on the Google Compute Engine cluster master instance.

### Google Cloud SQL

Google Cloud SQL is a MySQL database service on the Google Cloud Platform.

Follow the
[Getting Started](https://developers.google.com/cloud-sql/docs/before_you_begin)
instructions to create a Google Cloud SQL instance.

On the Hadoop master instance, under the `hdpuser`,
download the Google Cloud SQL command line tool and JDBC driver.
More on these instructions and tools can be found at
[Command Line Tool](https://developers.google.com/cloud-sql/docs/commandline).

    mkdir ~hdpuser/google_sql
    cd ~hdpuser/google_sql/
    wget http://dl.google.com/cloudsql/tools/google_sql_tool.zip

Install `unzip` and explode the `google_sql_tool.zip` file:

    sudo apt-get update
    sudo apt-get install unzip

    unzip google_sql_tool.zip

Authenticate the command line tool:

    ./google_sql.sh <instance>

Note that _instance_ is the fully qualified Google Cloud SQL instance name.

From the `google_sql.sh` prompt, issue:

    CREATE USER hdpuser@localhost IDENTIFIED BY 'hdppassword';
    GRANT ALL PRIVILEGES ON hivemeta.* TO hdpuser@localhost;

[You should select your own password here in place of _hdppassword_.]

Create the database `hivemeta`.  Note that Hive requires the database
to use `latin1` character encoding:

    CREATE DATABASE hivemeta CHARSET latin1;

Now update the `hive-site.xml` file in `/home/hdpuser/hive/conf` to connect to
the Google Cloud SQL database.  Add the following configuration:

    <property>
      <name>javax.jdo.option.ConnectionURL</name>
      <value>jdbc:google:rdbms://<instance>/hivemeta?createDatabaseIfNotExist=true</value>
    </property>
    <property>
      <name>javax.jdo.option.ConnectionDriverName</name>
      <value>com.google.cloud.sql.Driver</value>
    </property>
    <property>
      <name>javax.jdo.option.ConnectionUserName</name>
      <value>hdpuser</value>
    </property>
    <property>
      <name>javax.jdo.option.ConnectionPassword</name>
      <value>hdppassword</value>
    </property>

As a password has been added to this configuration file, it is recommended that
you make the file readable and writeable only by the hdpuser:

    chmod 600 ~hdpuser/hive/conf/hive-site.xml

Hive now needs the Google Cloud SQL JDBC driver.

The simplest method to add the JAR file to hive's CLASSPATH
is to copy the file to the `hive/lib/` directory:

    cp ~hdpuser/google_sql/google_sql.jar ~hdpuser/hive/lib/

When run, hive will now be able to use the Google Cloud SQL database as its
metastore.

### MySQL on Google Compute Engine

MySQL can be installed and run on Google Compute Engine.

On the Hadoop master instance, under the `hdpuser`,
use the `aptitude` package manager to install MySQL:

    sudo apt-get update
    sudo apt-get -y install mysql-server

When completed, create a database with mysqladmin for the hive metastore:

    sudo mysqladmin create hivemeta

When completed, create a user for the hive metastore.

Launch mysql:

    sudo mysql

At the MySQL shell prompt, issue:

    CREATE USER hdpuser@localhost IDENTIFIED BY 'hdppassword';
    GRANT ALL PRIVILEGES ON hivemeta.* TO hdpuser@localhost;

[You should select your own password here in place of _hdppassword_.]

Now update the `hive-site.xml` file in `/home/hdpuser/hive/conf` to connect to
the MySQL database.  Add the following configuration:

    <property>
      <name>javax.jdo.option.ConnectionURL</name>
      <value>jdbc:mysql://localhost/hivemeta?createDatabaseIfNotExist=true</value>
    </property>
    <property>
      <name>javax.jdo.option.ConnectionDriverName</name>
      <value>com.mysql.jdbc.Driver</value>
    </property>
    <property>
      <name>javax.jdo.option.ConnectionUserName</name>
      <value>hdpuser</value>
    </property>
    <property>
      <name>javax.jdo.option.ConnectionPassword</name>
      <value>hdppassword</value>
    </property>

As a password has been added to this configuration file, it is recommended that
you make the file readable and writeable only by the hdpuser:

    chmod 600 ~hdpuser/hive/conf/hive-site.xml

Hive now needs the Connector/J JDBC driver for MySQL.
Use the `aptitude` package manager to install it.

    sudo apt-get install libmysql-java

The simplest method to add the JAR file to hive's CLASSPATH
is to copy the file to the `hive/lib/` directory:

    cp /usr/share/java/mysql-connector-java.jar ~hdpuser/hive/lib/

When run, hive will now be able to use the MySQL database as its metastore.

Appendix B
----------
This section lists some useful file locations on the Hadoop master
instance:

     ---------------------|---------------------------------
    | File Description    | Path                            |
    |---------------------|---------------------------------|
    | Hadoop binaries     | /home/[hadoop]/hadoop-<version> |
    | Hive binaries       | /home/[hdpuser]/hive-<version>  |
    | Pig binaries        | /home/[hdpuser]/pig-<version>   |
    | HDFS NameNode Files | /hadoop/hdfs/name               |
    | HDFS DataNode Files | /hadoop/hdfs/data               |
    | Hadoop Logs         | /var/log/hadoop                 |
    | MapReduce Logs      | /var/log/hadoop                 |
    | Hive Logs           | /tmp/[hdpuser]                  |
    | Pig Logs            | [Pig launch directory]          |
     ---------------------|---------------------------------
