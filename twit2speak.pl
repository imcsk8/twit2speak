#!/usr/bin/perl


#converts a tweet to speech :P
# (c) Ivan Chavero <ichavero at chavero.com.mx>
# this program is licensed by the GNU license so you know what to do ;) http://www.gnu.org/copyleft/gpl.html

# in order yo use it you need to:
# install the next programs and perl packages
# espeak
# debian(s)
# apt-get install espeak 

# Gentoo
# emerge app-accessibility/espeak

# Net::Twitter
# ubuntu(s)
# apt-get install libnet-twitter-perl

# Gentoo
# emerge dev-perl/Net-Twitter

# you also have to create a twitter app and add the consumer_key, consumer_secret, token and token_secret
# to the appropiate variables

# if you have any problem contact me: @imcsk8 <ichavero at chavero.com.mx>

# this is a quick hack so there's no server or anything.
# if you want to be bothered by your friends constantly
# you can put the program on your cron or use this little bash magic:
#
#  while [ 1 ]; do ./twit2speak.pl; sleep 10 ; done

use strict;

use Net::Twitter;
use Scalar::Util 'blessed';
use Digest::MD5 qw(md5_base64);

my $consumer_key = "";
my $consumer_secret = "";
my $token = "";
my $token_secret = "";

my $SPOKEN_FILE = "spoken.log";

my $ESPEAK_COMMAND = "espeak -a150 -p30 -s 140 -v es-mx -k20 --stdin";


# When no authentication is required:
my $nt = Net::Twitter->new(legacy => 0);

# As of 13-Aug-2010, Twitter requires OAuth for authenticated requests
my $nt = Net::Twitter->new(
    traits   => [qw/OAuth API::REST/],
    consumer_key        => $consumer_key,
    consumer_secret     => $consumer_secret,
    access_token        => $token,
    access_token_secret => $token_secret,
);

#my $result = $nt->update('Hello, world!');

eval {
    #my $statuses = $nt->friends_timeline({ count => 5 });
    my $statuses = $nt->mentions({ count => 5 });
    for my $status ( @$statuses ) {
        print "$status->{created_at} <$status->{user}{screen_name}> $status->{text}\n";

		if ($status->{text} =~ /t2s/) {
			my $msg = $status->{text};
			$msg =~ s/\#t2s|t2s//g;
			$msg = "$msg " . $status->{user}{screen_name};
			if( check_spoken($msg) ){
				next;
			}
			set_spoken($msg);
			print $ESPEAK_COMMAND . " \'$status->{text}\'\n";
			#system($ESPEAK_COMMAND . " \'$msg\'" );
			open(COMMAND, "|$ESPEAK_COMMAND") || warn "Can't execute command";
			print COMMAND $msg;
			print COMMAND pack("c", "04"); 
			close(COMMAND);
		}
    }
	
};
if ( my $err = $@ ) {
    die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

    warn "HTTP Response Code: ", $err->code, "\n",
         "HTTP Message......: ", $err->message, "\n",
         "Twitter error.....: ", $err->error, "\n";
}


sub set_spoken {
	my $msg = shift;
	open(SPK, ">>$SPOKEN_FILE") || die "can't open $SPOKEN_FILE $!\n";
	print SPK md5_base64($msg) . "\n";
	close(SPK);
}

sub check_spoken {
	my $msg = shift;
	my $digest = md5_base64($msg);
	my $res = `grep $digest $SPOKEN_FILE`;
	if( $res ne ""){
		return 1;
	}  
	return 0;
}
