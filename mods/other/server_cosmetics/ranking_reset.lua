local queue_transfers = false

ctf_rankings.register_on_rank_reset(function(pname, rank)
	if rank and rank.place then
		if rank.place <= 120 then
			server_cosmetics.add_transfers(pname, {["server_cosmetics:headwear:sunglasses:black"] = "give"})
			queue_transfers = true
		end
	end
end)

core.register_on_shutdown(function()
	if queue_transfers then
		server_cosmetics.save_transfer_queue()
	end
end)
