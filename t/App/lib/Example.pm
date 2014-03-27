package Example;
use OX;
use ExampleController;

has thing => (
    is  => 'ro',
    isa => 'ExampleController',
);

router as {
    route '/thing'     => 'REST.thing.root';
    route '/thing/:id' => 'REST.thing.item';
    route '/hase' => 'thing.hase';
    route '/link' => 'thing.link';
};

no Moose; 1;
__END__

