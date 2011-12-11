== Prices 0.0.3 ==
by algritz
Created december 8th, 2011


Prices is allows to diplay a frame containing a list of items as well as their prices.
Its goal is to avoir to do back and forth between the Rift-Auction-Management tool and Rift.

Features:

* Displayed a list of items and their prices in a scrollable window, that can be shown via the "/prices" command

== Installation Instructions ==

* Download the addon
* Open Rift
* From character select, click the "Addons" button at the bottom
* Click the "Open Addon Directory" button
* Wait for the directory to open up
* Put the Prices folder into that directory
* Return to Rift
* Click "Refresh"
* Play the game!

== Usage ==
In order to update the values displayed in game, you need to edit the "prices.lua" file in your saved variable.
format is :

item_prices = {
	{
		{
			"item name # 1",
			"price #1"
		},
                {
                        "item name 2",
                        "price # 2"
       }
}}

-- As long as this format is preserved, the addon will be able to display the list and its associated values

* values are loaded only at login time. So it you need fresh values, logout, overwrite the content, then log back in.

To diplay the list in game type the "/Prices" command

== Thanks To ==

* Noax, your saved variable tutorial helped me a lot in this project
* Trion (ZorbaTHut)
