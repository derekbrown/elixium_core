defmodule UltraDark.Blockchain do
  alias UltraDark.Blockchain.Block
  alias UltraDark.Ledger
  alias UltraDark.UtxoStore

  @target_blocktime 120
  @diff_rebalance_offset 5

  @doc """
    Creates a List with a genesis block in it or returns the existing blockchain
  """
  def initialize do
    if Ledger.is_empty? do
      add_block([], Block.initialize)
    else
      Ledger.retrieve_chain
    end
  end

  @doc """
    Adds the latest block to the beginning of the blockchain
  """
  @spec add_block(list, Block) :: list
  def add_block(chain, block) do
    chain = [block | chain]

    Ledger.append_block(block)
    UtxoStore.update_with_transactions(block.transactions)
	
	if rem(length(chain), @diff_rebalance_offset) == 0, do: rebalance_difficulty chain

    chain
  end

  def recalculate_difficulty(chain) do
	last = List.first(chain)
	beginning = Enum.at(chain, max(length(chain) - @diff_rebalance_offset + 1, 0))
	avg_spb = (DateTime.to_unix(last.timestamp) - DateTime.to_unix(beginning.timestamp)) / @diff_rebalance_offset
	speed_ratio = @target_blocktime / avg_spb
	prev = last.difficulty

	# difficulty = log speed_ratio base 16 = log2(speed_ratio) / log2(16)
	diff = :math.log2(speed_ratio) / 4

	blue = "\e[34m"
	clear = "\e[0m"

	IO.puts "#{blue}difficulty of block#{clear} #{block.index} #{blue}set to#{clear} #{diff} #{blue}from#{clear} #{prev}"

	diff
  end
end
