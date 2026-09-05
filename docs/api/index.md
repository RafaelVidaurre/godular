# API reference

Godot generates these pages from the doc comments in the source. The same
text appears in the editor help (F1) when the plugin is enabled.

## Modules

```{toctree}
:maxdepth: 1

classes/class_gdlrmodule
classes/class_gdlrcapability
classes/class_gdlrmodulemanager
classes/class_gdlrmodulegraph
classes/class_gdlrmodulegraph.debugplugin
classes/class_gdlrmoduledefinition
```

## Middleware

```{toctree}
:maxdepth: 1

classes/class_gdlrmiddlewarepipeline
```

## Command bus

```{toctree}
:maxdepth: 1

classes/class_capgdlrcommandbus
classes/class_capgdlrcommandbus.command
classes/class_capgdlrcommandbus.commandenvelope
classes/class_capgdlrcommandbus.commandmeta
classes/class_capgdlrcommandbus.commandroute
classes/class_capgdlrcommandbus.commandresult
classes/class_capgdlrcommandbus.ratelimitinfo
classes/class_capgdlrcommandhandlers
classes/class_capgdlrcommandhandlers.context
classes/class_capgdlrcommandhandlers.localoutput
classes/class_gdlrcommandhandler
classes/class_gdlrcommandmiddleware
classes/class_capgdlrcommandtransport
classes/class_gdlrcommandtransportadapter
classes/class_capgdlrcommandrouter
```

## Jobs

```{toctree}
:maxdepth: 1

classes/class_capgdlrjobs
classes/class_capgdlrjobs.jobspec
classes/class_capgdlrjobs.job
classes/class_capgdlrjobsregistry
```

## Promises

```{toctree}
:maxdepth: 1

classes/class_gdbpromise
```

## Internals

Godular creates these classes for you. They are listed for contributors and
for readers who debug the module graph. Their interfaces can change in any
release.

```{toctree}
:maxdepth: 1

classes/class_gdlrdicontainer
classes/class_gdlrdicontainer.providerfactory
classes/class_gdlrmoduleprovider
classes/class_gdlrcommandpipeline
classes/class_gdlrcommandpipeline.pipelineentry
classes/class_gdlrmiddlewarepipeline.pipelineentry
```
