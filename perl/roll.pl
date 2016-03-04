#!/usr/bin/perl
#------------------------------------------------------------------------------
# $Id: roll,v 1.47 2005/04/19 19:56:11 chorn Exp chorn $
#------------------------------------------------------------------------------
# Author:                   chorn _at_ chorn.com
# Licensed under GNU GPLv2: http://www.gnu.org/licenses/gpl.txt
#------------------------------------------------------------------------------
# INSTALL
#
# Optionally, you can change $TRIGGER to be whatever you prefer.
# 1) Make roll executable.
# 2) Copy "roll" to somewhere in your path, like $HOME/bin/.
# 3) Link "roll" to your irssi scripts, with a .pl extentsion.
#
# chmod 0755 roll
# cp roll $HOME/bin/
# ln -s $HOME/bin/roll $HOME/.irssi/scripts/roll.pl
#
#------------------------------------------------------------------------------
use Getopt::Long;
use File::Slurp;
use Pod::Usage;
use strict;
use warnings;
#---------------------------------------------------------------------
use vars qw($TRIGGER $pod);
# Use this to invoke in Irssi
$TRIGGER = "!roll";

#---------------------------------------------------------------------
$pod = << "=cut";

=pod
=head1 NAME

roll - A flexible dice roller

=head1 SYNOPSIS

B<roll> [OPTION]... SPEC...

=head1 DESCRIPTION

B<Roll> will generate random sets of dice throws.  It works as a
command line program, or as an irssi script.

=head1 ARGUMENTS

=head2 OPTIONS

=over 8

=item B<--totals>

Only print the totals of each set rolled.

=back

=head2 SPECS

=over 8

=item B<6>
Roll 1 six-sided die

=item B<4 6>
Roll 4 six-sided dice

=item B<4d6>
As above

=item B<4D6>
As above, drop the lowest die

=item B<6x4D6>
Roll 6 sets as above

=item B<2d6+1>
Roll 2 six-sided dice and add 1

=item B<2d6-1>
Roll 2 six-sided dice and subtract 1

=item B<3x2d6+1>
Roll 3 sets of 2 six-sided dice and add 1 to each set

=item B<4+4>
Roll 1 four-sided die and add 4

=item B<1d10r>
Roll 1d10, reroll 1s

=item B<1d10r+3>
As above, add 3

=back

=head1 BUGS

None that I'm aware of.

=head1 AUTHOR

chorn _at_ chorn.com

=head1 LICENSE

GNU GPLv2, available at http://www.gnu.org/licenses/gpl.txt

=cut

#---------------------------------------------------------------------
sub roll($$)
{
  my ($o_totals, $expressions) = @_;

  return "" if(!defined $expressions);
  my $rtn = "";

  for my $spec (split /[\s,]+/, $expressions)
  {
    next if($spec eq '' || !defined $spec);

    if($spec !~ /^[0-9xdr+-]+$/i)
    {
      $rtn .= "IGNORED: $spec\n";
      next;
    }

    my $iterations = 1;
    my $die = 20;
    my $drop = 0;
    my $reroll = 0;
    my $totals = $o_totals;
    my $sets = 1;
    my $modifier = 0;

    if($spec =~ s/([+-]\d+)$//)
    {
      $modifier = $1;
    }

    if($spec =~ s/r$//i)
    {
      $reroll = 1;
    }

    if($spec =~ s/^(\d+)x//i)
    {
      $sets = $1;
    }
    elsif($spec =~ s/x(\d+)$//i)
    {
      $sets = $1;
    }

    if($spec =~ /^(\d+)$/)
    {
      $iterations = 1;
      $die = $spec;
    }

    if($spec =~ /D/)
    {
      $drop = 1;
    }

    if($spec =~ /d/i)
    {
      ($iterations, $die) = split /d/i, $spec;
    }

    $iterations = 1 if($iterations =~ /[^\d]/ || $iterations < 1 || $iterations > 30);
    $die = 20 if($die =~ /[^\d]/ || $die < 1 || $die > 1000000000);
    $sets = 6 if($sets =~ /[^\d]/ || $sets < 1 || $sets > 40);
    $drop = 0 if($iterations == 1);

    $rtn .= rolldice($sets, $iterations, $die, $modifier, $drop, $reroll, $totals);
  }

  return $rtn;
}
#---------------------------------------------------------------------
sub rolldice($$$$$$$)
{
  my ($sets, $iterations, $die, $modifier, $drop, $reroll, $totals) = @_;
  my $rand_num;
  my $rtn;

  my $width = length($die);

  for(1 .. $sets)
  {
    my @scores;
    my $lowest = $die;
    my $total = 0;
    my $shown = 0;

    for(1 .. $iterations)
    {
      if($reroll && ($die != 1))
      {
        $rand_num = 1;
        while ($rand_num == 1)
        {
          $rand_num = int(rand() * $die) + 1;
        }
      }
      else
      {
        $rand_num = int(rand() * $die) + 1;
      }

      if ($rand_num < $lowest)
      {
        $lowest = $rand_num;
      }

      push @scores, $rand_num;
    }

    if(! $totals)
    {
      $rtn .= $iterations . "d" . $die;
      $rtn .= 'r' if($reroll);

      if($modifier != 0)
      {
        $rtn .= '+' if($modifier > 0);
        $rtn .= '-' if($modifier < 0);
        $rtn .= abs($modifier);
      }

      $rtn .= ": ";
    }

    for my $score (@scores)
    {
      if((($shown++ > 0) || ($lowest eq "#")) && ( ! $totals))
      {
        $rtn .= " + ";
      }

      if(($score == $lowest) && $drop)
      {
        if(! $totals)
        {
          $rtn .= sprintf("[%" . $width . "s]", $score);
        }

        $lowest = "-1";
      }
      else
      {
        if(! $totals && $iterations > 1)
        {
          $rtn .= " " if($drop);
          $rtn .= sprintf("%" . $width . "s", $score);
          $rtn .= " " if($drop);
        }

        $total += $score;
      }
    }

    if(! $totals && $iterations > 1)
    {
      $rtn .= " = ";
    }

    if($modifier != 0)
    {
      if(! $totals)
      {
        $rtn .= sprintf("%" . ($width+1) . "s ", $total);
        $rtn .= '+' if($modifier > 0);
        $rtn .= '-' if($modifier < 0);
        $rtn .= ' ' . abs($modifier) . ' = ';
      }

      $total += $modifier;
    }

    $rtn .= sprintf("%" . ($width+1) . "s\n", $total);
  }

  return $rtn;
}
#---------------------------------------------------------------------
sub roller_hook($)
{
  my ($msg) = @_;

  if($msg =~ /$TRIGGER/i && $msg !~ /\:/) #Invocation
  {
    if($msg =~ /help/i)
    {
      return <<"EOH";
Usage: $TRIGGER SPEC [SPEC...]
 4d6 As above
 4D6 As above, drop the lowest die
 3x2d6+1 Roll 3 sets of 2 six-sided dice and add 1 to each set
EOH

    }
    elsif($msg =~ /^$TRIGGER([0-9xdr+-\s]+)$/i)
    {
      return roll(0, $1);
    }
  }

  return undef;
}
#---------------------------------------------------------------------
sub event_message_public($$$$$)
{
  my ($server, $msg, $nick, $hostmask, $channel) = @_;

  my $rtn = roller_hook($msg);

  return if(! defined $rtn);

  for (split /\n/, $rtn)
  {
    Irssi::command("MSG -$server->{tag} -channel $channel [$nick] $_");
  }
}
#---------------------------------------------------------------------
sub event_message_own_public($$$)
{
  my ($server, $msg, $channel) = @_;

  event_message_public($server, $msg, $server->{'nick'}, undef, $channel);
}
#---------------------------------------------------------------------
sub event_message_private($$$$)
{
  my ($server, $msg, $nick, $address) = @_;

  my $rtn = roller_hook($msg);
  return if(!defined $rtn);

  for (split /\n/, $rtn)
  {
    Irssi::command("MSG -$server->{tag} $nick $_");
  }
}
#---------------------------------------------------------------------
sub event_message_own_private($$$$)
{
  my ($server, $msg, $target, $otarget) = @_;

  event_message_private($server, $msg, $server->{'nick'}, $target);
}
#---------------------------------------------------------------------
sub event_roll($$$)
{
  my ($content, $item, $witem) = @_;

  my $rtn = roll(0, $content);

  if(defined $rtn)
  {
    for my $line (split /\n/, $rtn)
    {
      Irssi::print($line);
    }
  }
}
#---------------------------------------------------------------------
sub event_help($$$)
{
  my ($content, $item, $witem) = @_;
	return if($content !~ /roll/);

  my $podin = "/tmp/.podin.$$";
  my $podout = "/tmp/.podout.$$";
  write_file($podin, {binmode => ':raw' }, $pod ) ;
  pod2usage(-exitval => "NOEXIT", -verbose => 1, -input => $podin, -output => $podout);
  my $help = read_file($podout);
  unlink $podin;
  unlink $podout;

  for my $line (split /\n/, $help)
  {
    Irssi::print($line);
  }
}
#---------------------------------------------------------------------
if($0 eq '-e') # Irssi
{
  require Irssi;
  use vars qw($VERSION %IRSSI);

  $VERSION = '$Id: roll,v 1.47 2005/04/19 19:56:11 chorn Exp chorn $';
  %IRSSI = (
    authors     => 'chorn',
    name        => 'Roll',
    description => 'Flexible Dice Roller',
    license     => 'GNU GPLv2'
   );

  Irssi::signal_add_last('message public',      'event_message_public');
  Irssi::signal_add_last('message own_public',  'event_message_own_public');
  Irssi::signal_add_last('message private',     'event_message_private');
  Irssi::command_bind('roll', 'event_roll');
  Irssi::command_bind('help','event_help', 'Irssi commands');
  Irssi::print('Roller Loaded, try /help roll');

  1;
}
elsif($0 =~ /(\.cgi)/) # CGI
{
  1;
}
else # command line
{
  my $help = 0;
  my $totals = 0;

  my @GetoptList;

  # Parse Arguments.
  push @GetoptList, "help", \$help;
  push @GetoptList, "totals", \$totals;
  GetOptions(@GetoptList) || pod2usage(-exitval => 1, -verbose => 1);

  if($help)
  {
    delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};
    no strict;
    no warnings;
    pod2usage(-exitval => 0, -verbose => 1);
  }

  @ARGV = ( "$ARGV[0]d$ARGV[1]" ) if(scalar(@ARGV) == 2 && ($ARGV[0] =~/^(\d+)$/) && ($ARGV[1] =~/^(\d+)$/));

  my $result = roll($totals, join(' ', @ARGV));
  print $result if (defined $result);
  exit 0;
}
#---------------------------------------------------------------------
