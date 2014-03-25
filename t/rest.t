#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Path::Router;
use Plack::Test;

BEGIN {
    use_ok('OX::Application');
}

use lib 't/App/lib';

use Example;

my $app = Example->new;
isa_ok($app, 'Example');
isa_ok($app, 'OX::Application');

my $router = $app->router;
isa_ok($router, 'Path::Router');


path_ok($router, $_, '... ' . $_ . ' is a valid path')
for qw[
    /thing
    /thing/123
    /hase
];


#routes_ok($router, {
#    'hase'      => { page => 'index' },
#    'thing'   => { page => 'inc'   },
# #   'dec'   => { page => 'dec'   },
# #   'reset' => { page => 'reset' },
#},
#"... our routes are valid");


test_psgi
      app    => $app->to_app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/thing");
              my $res = $cb->($req);
              is($res->content,'a list of things');
          }
          {
              my $req = HTTP::Request->new(PUT => "http://localhost/thing");
              my $res = $cb->($req);
              is($res->content,'create thing');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/thing/123");
              my $res = $cb->($req);
              is($res->content,'view thing 123');
          }
          {
              my $req = HTTP::Request->new(POST => "http://localhost/thing/123");
              my $res = $cb->($req);
              is($res->content,'update thing 123');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/hase");
              my $res = $cb->($req);
              is($res->content,'hase');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/link");
              my $res = $cb->($req);
              is($res->content,'hase');
          }

      };

done_testing;
