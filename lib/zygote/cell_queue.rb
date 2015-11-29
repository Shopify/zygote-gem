require 'zygote/memory'

# An entry into the queue
class CellQueueEntry < SuperModel::Base
  include SuperModel::Marshal::Model
end

# A means of storing Cell queue data for a given sku
module CellQueue
  extend self
  COLLECTION = :assets
  ARRAY_KEY = :cell_queue
  Memory.load

  def push(key, data)
    entry = CellQueueEntry.find_by_name(key)
    unless entry
      entry = CellQueueEntry.new(name: key, data: [])
      entry.save
    end
    entry.data << data
    entry.save
    Memory.save
  end

  def shift(key)
    entry = CellQueueEntry.find_by_name(key)
    return nil unless entry
    first = entry.data.shift
    entry.save
    Memory.save
    first
  end

  def show(key)
    entry = CellQueueEntry.find_by_name(key)
    entry ? entry.data : []
  end

  def purge(key)
    entry = CellQueueEntry.find_by_name(key)
    entry.data = [] if entry
    entry.save if entry
  end

  def all()
    CellQueueEntry.all
  end
end
