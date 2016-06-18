[![travis ci](https://travis-ci.org/Shopify/zygote-gem.svg)](https://travis-ci.org/Shopify/zygote-gem)

# Zygote

Zygote is a bootstrap automation framework that allows you to easily bootstrap servers and switches.

# Usage

To get started:

```
require 'zygote'

Zygote::Server.new(
  cells: File.expand_path('../cells', __FILE__)
).run
```

Where 'cells' is a path to cells containing erb templates describing how to boot your system - shown in greater detail below.

Additionally, create a configuration file at 'config/cells.yml' of the following structure:

```
index:
  timeout: 0 # timeout in seconds, 0 for none
  cells:
    installers:
      delegate: live
      menu: # A menu with submenu entries
        class: os
        label: "Install an operating system"
        submenu:
          ubuntu:
            label: "Install Ubuntu"
            args:
              arbitrary: data
    memtest:
      menu:
        class: util
        label: "Run Memtest86"
      args:
        kernel_params: console=ttyS1,115200n8
        passes: 5
```

# iPXE

Zygote supports bootstrapping servers through generating iPXE menus

## Menu generation

Zygote reads cells.yml, and generates menus and submenus. Every menu entry has a top-level iPXE symbol, and every submenu has a symbol formed by joining the top-level menu grouping with the specific menu entry.

For instance, a top-level menu item called 'memtest' would tagged in iPXE with:

```
:memtest
```

This symbol would be called (via an iPXE ```goto```) if the memtest menu item is selected.

Likewise, a submenu called 'utility' with the entry 'rescue' would be tagged as:

```
:utility-rescue
```

Each menu and submenu can have a user-friendly description using the 'label' field. Additional arguments or parameters are allowed nested under the 'args' field. Any URI parameters are merged with this, as is any JSON encoded post data.

Each entry may invoke an action, by default the action is called 'boot', but this can be overriden with the 'action' field.

Each entry will by default correspond to rendering an erb file at:

```
cell/<entry>/<action>
```

Where this corresponds to a file on disk called:

```
cells/<entry>/<action>.erb
```

So, if you have an entry called 'memtest', and you want to use the default action of 'boot', create the file with the necessary iPXE directives to boot it at:

```
cells/memtest/boot.erb
```

If you want to use the boot logic of another cell, you can delegate to it using the 'delegate' field. So we could have memtest delegate to using another cell's named 'default' to boot it if we chose to. This can be useful if your boot logic is shared between cells.

If you want to share code within any erb file, you may use a partial. All partials are relative to the cells directory, and strings or symbols are accepted.

For instance, adding:

```
<%= partial('util/common', {some: 'optional', variables: 'to help render'}) %>
```

The template at ```cells/util/common.erb``` will be rendered in the current template.

# Automation

Zygote supports automation through a simple queuing mechanism.

## Enqueuing cells to a sku

Let's say we have the asset SKU-1234567, as identified by iPXE, and we want to run the cell 'ubuntu-automatic'

```
curl -X POST localhost:7000/queue/SKU-1234567/ubuntu-automatic
```

The next time the asset boots, the boot menu will be bypassed entirely and the ubuntu-automatic entry will be loaded.

Any post parameters provided will be merged into the options hash at boot time, which allows for fairly dynamic behaviour.

You may of course push multiple cells to the queue for a given asset. This allows you to chain from one cell into another - assuming they each complete and reboot successfully.

## Pre-selected cells

By adding the ```selected_cell``` parameter, you may jump directly to a particular cell to execute using an iPXE ```goto``` statement. This is quite powerful, as it prevents the need for human interaction. Combined with zygote's queueing, you can chain from one action into another by rebooting after each action.

So, if we set the URI parameter ```selected_cell=memtest```, the menu will never be displayed, and we'll jump directly to the memtest label, and execute the memtest action. 

## Identifiers

Before the iPXE menu is rendered, an identifier may mutate the parameters used at boot time arbitrarily. This provides a means to hook in custom code to alter the boot behavior. By subclassing ```Zygote::Identifier``` you may shadow the ```identify``` method, to mutate the params hash as shown:

```
module Zygote
  class MyIdentifier < Zygote::Identifier
    def identify
      @params['selected_cell'] = MyCustomRubyCode.decide_what_to_do
      @params
    end
  end
end

```
Define this code after requiring the zygote gem.

## Queue management

You may of course perform basic queue operations:

You may view the JSON of the queue:

```
curl -X GET localhost:7000/queue/SKU-1234567
```

You may purge the queue completely:

```
curl -X DELETE localhost:7000/queue?sku=1234567 # FIXME: this is orthogonal, figure out why DELETE collides with GET
```

# Testing

Tested automatically using [travis ci](https://travis-ci.org/dalehamel/zygote-gem).

Most tests are fixture based, as the app primarily renders templates.

To regenerate fixtures, set FIXTURE\_RECORD=true before running test.
