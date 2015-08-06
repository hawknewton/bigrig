0.0.2
=====
* Profiles can add new containers

0.0.3
=====
* `bigrig ship` takes credentials

0.0.4
=====
Bump read timeout to one hour

0.0.5
=====
Add -c flag to cleanup after ship

0.0.7
=====
Add profiles to most commands

0.1.0
=====
Add `volumes` attriute

0.1.1
=====
* Profiles with volumes or volumes_from now augment eachother
* Profiles are applied based on the order they are defined
* Enahnce output formatter

0.1.2
=====
* Remove pry-bedbug

0.1.4
=====
* Unbreak build caching

0.2.0
=====
* Added `scan` functionality

0.2.2
=====
* scanned containers no longer restart their dependencies

0.3.0
=====
* Honor .dockerignore, if present

0.3.1
=====
* OutputParser now emits newlines correctly

0.4.0
=====
* Add wait_for semantics

0.4.1
=====
* wait_for failures fail bigrig

0.4.2
=====
* Fix nasty jruby incompadability

0.5.0
=====
**BREAKING CHANGE**
* removed wait_for from bigrig.json.  We now wait for the script at
  `/bigrig-wait.sh`, if present

0.6.0
=====
* Set container hostname based on container hostname

0.6.1
=====
* Use container hostname for hostname.  Might be a really bad idea.

0.6.2
=====
* Fix for docker 1.7.1
