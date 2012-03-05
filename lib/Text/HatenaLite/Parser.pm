package Text::HatenaLite::Parser;
use strict;
use warnings;
our $VERSION = '1.0';
use Regexp::Assemble;
use Text::HatenaLite::Definitions;

my $Patterns = $Text::HatenaLite::Definitions::Notations;

my $Regexp = Regexp::Assemble->new(track => 1);
for (@$Patterns) {
    $Regexp->add($_->{pattern});
}

my $PatternToType = {map { $_->{pattern} => $_->{type} } @$Patterns};
my $PatternToPP = {map { $_->{pattern} => $_->{postprocess} } @$Patterns};

sub parse_string {
    my (undef, $str) = @_;
    
    my @token;
    while ((length $str) && $Regexp->match($str)) {
        my $begin = $Regexp->mbegin->[0];
        my $end = $Regexp->mend->[0];
        last if $begin == $end;
        if ($Regexp->mbegin->[0] > 0) {
            push @token, {type => 'text',
                          values => [substr($str, 0, $Regexp->mbegin->[0])]};
        }
        
        my $pattern = $Regexp->matched;
        push @token, {
            type => ($PatternToType->{$pattern} || die "Unknown pattern: |$pattern|"),
            values => $Regexp->mvar,
        };
        if (my $pp = $PatternToPP->{$pattern}) {
            $pp->($token[-1]->{values});
        }
        
        $str = substr($str, $Regexp->mend->[0]);
    }
    push @token, {type => 'text', values => [$str]} if length $str;

    return \@token;
}

1;
