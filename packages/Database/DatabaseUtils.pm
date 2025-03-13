package DatabaseUtils;

use strict;
use warnings;
use JSON;
use DBI;

our $dbh;

sub connect_to_database {
    my $dsn = "DBI:Pg:dbname=mydb;host=localhost;port=5432";
    my $db_user = 'postgres';
    my $db_password = 'Admin.123';
    $dbh = DBI->connect($dsn, $db_user, $db_password, { AutoCommit => 1, RaiseError => 1 })
        or die "Failed to connect to PostgreSQL database: " . $DBI::errstr;
    print "Connected to database\n";
}


sub create_tables {

    ## Create users table
    $dbh->do(q{
    CREATE TABLE IF NOT EXISTS users (
        user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        username VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL,
        display_name VARCHAR(255),
        is_admin BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    }) or die "Create table failed: $dbh->errstr()";

    ## Create chats table
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS chats (
            chat_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            chat_name VARCHAR(100),
            is_group BOOLEAN,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    }) or die "Create table failed: $dbh->errstr()";

    ## Create chat_participants table
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS chat_participants (
            chat_id UUID REFERENCES chats(chat_id) ON DELETE CASCADE,
            user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
            PRIMARY KEY (chat_id, user_id)
        )
    }) or die "Create table failed: $dbh->errstr()";

    ## Create messages table
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS messages (
            message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            chat_id UUID REFERENCES chats(chat_id) ON DELETE CASCADE,
            senderid UUID REFERENCES users(user_id) ON DELETE CASCADE,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    }) or die "Create table failed: $dbh->errstr()";

    ## Create user_sessions table
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS user_sessions (
            session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
            token VARCHAR(255) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    }) or die "Create table failed: $dbh->errstr()";
}



1;