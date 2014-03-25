package OX::RouteBuilder::REST;
use Moose;
use namespace::autoclean;

# ABSTRACT: OX::RouteBuilder which routes to an action method in a controller class based on HTTP verbs

use Try::Tiny;

with 'OX::RouteBuilder';

sub import_DIES_more_than_one_toplevel_router {
#sub import {
    my $caller = caller;
    my $meta = Moose::Util::find_meta($caller);
    $meta->add_route_builder('OX::RouteBuilder::REST');
}

sub import_NOT_WORKING_all_routes_404 {
#sub import {
    my $caller = caller;
    my $meta = Moose::Util::find_meta($caller);
    $meta->add_route_builder('OX::RouteBuilder::REST');
    $meta->add_route_builder('OX::RouteBuilder::ControllerAction');
    $meta->add_route_builder('OX::RouteBuilder::HTTPMethod');
    $meta->add_route_builder('OX::RouteBuilder::Code');

    $OX::CURRENT_CLASS=$meta;
}

sub compile_routes {
    my $self = shift;
    my ($app) = @_;

    my $spec = $self->route_spec;
    my $params = $self->params;
    my ($defaults, $validations) = $self->extract_defaults_and_validations($params);
    $defaults = { %$spec, %$defaults };

    my $target = sub {
        my ($req) = @_;

        my $match = $req->mapping;
        my $c = $match->{controller};
        my $a = $match->{action};

        my $err;
        my $s = try { $app->fetch($c) } catch { ($err) = split "\n"; undef };
        return [
            500,
            [],
            ["Cannot resolve $c in " . blessed($app) . ": $err"]
        ] unless $s;

        my $component = $s->get;
        my $method = uc($req->method);
        my $action = $a .'_'.$method;

        if ($component->can($action)) {
            return $component->$action(@_);
        }
        else {
            return [
                500,
                [],
                ["Component $component has no method $action"]
            ];
        }
    };

    return {
        path        => $self->path,
        defaults    => $defaults,
        target      => $target,
        validations => $validations,
    };
}

sub parse_action_spec {
    my $class = shift;
    my ($action_spec) = @_;

    return if ref($action_spec);
    return unless $action_spec =~ /^REST\.(\w+)\.(\w+)$/;

    return {
        controller => $1,
        action     => $2,
        name       => $action_spec,
    };
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

  package MyApp;
  use OX;
  use OX::RouteBuilder::REST;

  has thing => (
      is  => 'ro',
      isa => 'MyApp::Controller::Thing',
  );

  router [map {'OX::RouteBuilder::'.$_} qw(ControllerAction Code HTTPMethod REST )] => as {
      route '/thing'     => 'REST.thing.root';
      route '/thing/:id' => 'REST.thing.item';
  };


  package MyApp::Controller::Thing;
  use Moose;

  sub root_GET {
      my ($self, $req) = @_;
      ... # return a list if things
  }

  sub root_PUT {
      my ($self, $req) = @_;
      ... # create a new thing
  }

  sub item_GET {
      my ($self, $req, $id) = @_;
      ... # view a thing
  }

  sub item_POST {
      my ($self, $req, $id) = @_;
      ... # update a thing
  }


=head1 DESCRIPTION

This is an L<OX::RouteBuilder> which allows to a controller class based on the
HTTP method used in the request. The C<action_spec> should be a string
corresponding to a service which provides a controller instance. When a request
is made for the given path, it will look in that class for a method which
corresponds to the lowercased version of the HTTP method used in the request
(for instance, C<get>, C<post>, etc). If no method is found, it will fall back
to looking for a method named C<any>. If that isn't found either, an error will
be raised.

C<action> will automatically be added to the route as a default, as well as
C<name> (which will be set to the same thing as C<action>).

=for Pod::Coverage
  import
  compile_routes
  parse_action_spec

=cut


