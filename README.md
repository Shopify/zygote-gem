[![Circle CI](https://circleci.com/gh/Shopify/zygote.svg?style=svg&circle-token=b14c427cac4c84b3f725a037be4bddf8978463df)](https://circleci.com/gh/Shopify/zygote)

# Zygote

Zygote is a PXE automation framework that allows you to easily generate an iPXE boot menus.

# Technical

## Menus

Implementing a menu is easy.

* Create a folder inside 'cells'
* Add a menu.erb file to your folder, this can be boiler plate or as complicated as you want
* Add a boot.erb that describes how to actually boot your desired cell.
* Add a 'cell' entry to config/cells.yml
 * Say how it should be displayed, and what it's classification is
 * Add any parameters you want to render here (constants for instance)

You can arbitrarily render additional templates if you need to by hitting the /cell/NAME/ACTION endpoint. Name is the name of the cell, action is the name of the .erb file.

## Under the hood

Zygote is powered by the GenesisReactor, which is an event machine driven framework.

But, you probably don't have to care about that. You just need to know asynchronous actions are available to you.

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

Tested automatically using [circle ci](https://circleci.com/gh/Shopify/zygote).

Most tests are fixture based, as the app primarily renders templates.

To regenerate fixtures, set FIXTURE\_RECORD=true before running test.
