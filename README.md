# SBT Shell Release #

## Overview ##

This project is a simple shell ([Bash][bash]) script which can be used to release a [SBT][sbt] project.

I created it because I frequently had use cases for releasing projects which were not directly supported by the [sbt-release][sbt-release] plugin and to me it seemed more straight forward to implement them directly in a shell script rather than customizing the release process of [sbt-release][sbt-release]. This is clearly very subjective and if you do not have these use cases nor share these feelings then [sbt-release][sbt-release] is the more canonical method of releasing in the [Scala][scala] ecosystem.

[bash]: https://www.gnu.org/software/bash/ "Bash"

[sbt-release]: https://github.com/sbt/sbt-release "SBT Release"

[scala]: https://www.scala-lang.org/ "Scala Language"

[sbt]: https://www.scala-sbt.org "SBT"
