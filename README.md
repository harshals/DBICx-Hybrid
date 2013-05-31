# NAME

DBICx::Hybrid - 

Some common routines i generally use combined in form of ResultSet, ResultClass and Result Classes.

# VERSION

Version 0.001

# DESCRIPTION

customised exentions for DBIC::Result and ResultSets. Basically allows you to 
modify schema on quick and dirty basis. Uses DBIx::Class::FrozenColumns to store
data as Storable within a column. Please refer to individual classes for more detail explaination.

only pre-requisite is that overlaying schema must define a \`user\` attribute, having current user\_id 
or session\_id.



# AUTHOR

Harshal Shah (harshal.shah@gmail.com)

# BUGS

shoot an email to harshal.shah@gmail.com

# COPYRIGHT & LICENSE

Copyright (C) 2013 Harshal Shah

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.




