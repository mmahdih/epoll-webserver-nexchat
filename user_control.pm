package user_control;

use strict;
use warnings;
use Data::Dumper;
use JSON;
use feature 'say';
use Cwd;

# Constructor
sub new {
    my $class = shift;
    my $self = {
        username => shift,
        password => shift
    };
    return bless $self, $class;
}


# authenticate user
sub authenticate {
    my ($self, $email, $password_hash) = @_;
    my $users = $self->get_users();

    
    print Dumper($users);
    foreach my $user (@$users) {
        if ( $user->{email} eq $email && $user->{password} eq $password_hash ) {
            print "Login successful\n";
            return 1;
        }
    }
    print "Wrong credentials\n";
    return 0;
}

sub get_users {
    my $users;
    my $base_dir = getcwd();
    if ( -s "$base_dir/users.json" ) {
        open my $fh, '<', "$base_dir/users.json" or die $!;
        local $/ = undef;
        my $json_data = <$fh>;
        $users = decode_json($json_data);
        close $fh;
    } else {
        $users = [];
    }
    return $users;
}

# Method to change password
sub change_password {
    my ($self, $new_password) = @_;
    $self->{password} = $new_password;
}

sub login_check {
    my ($self, $cookie) = @_;
    if ($cookie && $cookie =~ /^name=(.*)$/m) {
        print "Already logged in\n";
        return 1;
    } else {
        print "Not logged in\n";
        return 0;
    }

}

# Method to reset password
sub reset_password {
    my ($self, $new_password) = @_;
    $self->{password} = $new_password;
}

# Method to delete user
sub delete_user {
    my ($self) = @_;
    delete $self->{username};
    delete $self->{password};
}

# Method to get username
sub get_username {
    my ($self) = @_;
    return $self->{username};
}

# Method to get password
sub get_password {
    my ($self) = @_;
    return $self->{password};
}

# Method to set username
sub set_username {
    my ($self, $new_username) = @_;
    $self->{username} = $new_username;
}

# Method to set password
sub set_password {
    my ($self, $new_password) = @_;
    $self->{password} = $new_password;
}

# Method to get user details
sub get_user_details {
    my ($self) = @_;
    return "Username: $self->{username}, Password: $self->{password}";
}

# Method to log out user
sub log_out {
    my ($self) = @_;
    print "User $self->{username} logged out\n";
}










1;