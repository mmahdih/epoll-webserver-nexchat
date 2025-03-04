#!/usr/bin/perl
use strict;
use warnings;
use DBI;

# Connect to PostgreSQL database
my $dbh = DBI->connect("DBI:Pg:dbname=mydb", 'postgres', 'Admin.123', { AutoCommit => 1, RaiseError => 1 })
    or die "Failed to connect to PostgreSQL database: " . $DBI::errstr;

print "Connected to database\n";

# Create table if not exists
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS city (
        id SERIAL PRIMARY KEY,
        fname VARCHAR(20),
        lname VARCHAR(20),
        ext VARCHAR(20)
    )
}) or die "Create table failed: $dbh->errstr()";

# Prepare insert statement
my $sth = $dbh->prepare(q{INSERT INTO city (fname, lname, ext) VALUES (?, ?, ?)})
    or die "Prepare statement failed: $dbh->errstr()";

# Execute insert
$sth->execute('Mahdi', 'Haidary', 'com')
    or die "Insert failed: $dbh->errstr()";

# Select data
$sth = $dbh->prepare("SELECT lname, fname, ext FROM city")
    or die "Prepare statement failed: $dbh->errstr()";

$sth->execute() or die "Select failed: $dbh->errstr()";

# Fetch and print results
while (my @row = $sth->fetchrow_array()) {
    print("$row[0], $row[1]\t$row[2]\n");
}

# Cleanup
$sth->finish();
$dbh->disconnect();
