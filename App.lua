local _, Addon = ...;

Addon.APP = CreateFrame( 'Frame' );
Addon.APP:RegisterEvent( 'ADDON_LOADED' );
Addon.APP:SetScript( 'OnEvent',function( self,Event,AddonName )
	if( AddonName == 'jIgnores' ) then
		if( InCombatLockdown() ) then
			return;
		end

		Addon.APP.ParseIgnores = function( self )
			local button;
			local NumIgnores = C_FriendList.GetNumIgnores();
			local NumBlocks = BNGetNumBlocked();

			-- Headers stuff
			local ignoredHeader, blockedHeader;
			if( NumIgnores > 0 ) then
				ignoredHeader = 1;
			else
				ignoredHeader = 0;
			end
			if( NumBlocks > 0 ) then
				blockedHeader = 1;
			else
				blockedHeader = 0;
			end

			local NumOnline = 0;
			local lastIgnoredIndex = NumIgnores + ignoredHeader;
			local lastBlockedIndex = lastIgnoredIndex + NumBlocks + blockedHeader;
			local numEntries = lastBlockedIndex;

			-- selection stuff
			local selectedSquelchType = FriendsFrame.selectedSquelchType;
			local selectedSquelchIndex = 0 ;
			if( selectedSquelchType == SQUELCH_TYPE_IGNORE ) then
				selectedSquelchIndex = C_FriendList.GetSelectedIgnore() or 0;
			elseif( selectedSquelchType == SQUELCH_TYPE_BLOCK_INVITE ) then
				selectedSquelchIndex = BNGetSelectedBlock();
			end
			if( selectedSquelchIndex == 0 ) then
				if( NumIgnores > 0 ) then
					selectedSquelchType = SQUELCH_TYPE_IGNORE;
					selectedSquelchIndex = 1;
				elseif( numBlocks > 0 ) then
					selectedSquelchType = SQUELCH_TYPE_BLOCK_INVITE;
					selectedSquelchIndex = 1;
				end
			end

			local Names = {};
			local scrollOffset = FauxScrollFrame_GetOffset(FriendsFrameIgnoreScrollFrame);
			local squelchedIndex;
			for i = 1, IGNORES_TO_DISPLAY, 1 do
				squelchedIndex = i + scrollOffset;
				button = _G[ 'FriendsFrameIgnoreButton'..i ];
				button.type = nil;

				if( squelchedIndex <= lastIgnoredIndex ) then
					-- ignored
					button.index = squelchedIndex - ignoredHeader;
					local name = C_FriendList.GetIgnoreName(button.index);

					if( name ) then
						self:SetIgnore( name );
						button.type = SQUELCH_TYPE_IGNORE;
					end
				elseif( squelchedIndex <= lastBlockedIndex ) then
					-- blocked
					button.index = squelchedIndex - lastIgnoredIndex - blockedHeader;
					local blockID, blockName = BNGetBlockedInfo(button.index);
					button.type = SQUELCH_TYPE_BLOCK_INVITE;
				end
				if( selectedSquelchType == button.type and selectedSquelchIndex == button.index ) then
					NumOnline = NumOnline + 1;
				end
			end
 		end

 		Addon.APP.ParseMembers = function( self )
	 		if( IsInRaid() ) then
	 			for i=1,40 do
	 				if( UnitName( 'raid'..i ) ) then
	 					Addon.APP:SetPartyMember( UnitName( 'raid'..i ) );	
	 				end
	 			end
	 		elseif( IsInGroup() ) then
	 			for i=1,4 do
	 				if( UnitName( 'party'..i ) ) then
	 					Addon.APP:SetPartyMember( UnitName( 'party'..i ) );	
	 				end
	 			end
	 		end
 		end

 		Addon.APP.SetIgnore = function( self,Ignore )
 			local Found = false;
 			for i,V in pairs( self.Ignores ) do
 				if( Addon:Minify( V ):find( Addon:Minify( Ignore ) ) ) then
 					Found = true;
 				end
 			end
 			if( not Found ) then
 				table.insert( self.Ignores,Ignore );
 			end
 		end

 		Addon.APP.GetIgnores = function( self )
 			return self.Ignores;
 		end

 		Addon.APP.SetPartyMember = function( self,Member )
 		 	local Found = false;
 			for i,V in pairs( self.Members ) do
 				if( Addon:Minify( V ):find( Addon:Minify( Member ) ) ) then
 					Found = true;
 				end
 			end
 			if( not Found ) then
 				table.insert( self.Members,Member );
 			end
 		end

 		Addon.APP.GetPartyMembers = function( self )
 			return self.Members;
 		end

		--
		--  Module init
		--
		--  @return void
		Addon.APP.Init = function( self )

			self.Ignores,self.Members = {},{};
			self.Events = CreateFrame( 'Frame' );
			self.Events:RegisterEvent( 'IGNORELIST_UPDATE' );
			self.Events:RegisterEvent( 'GROUP_ROSTER_UPDATE' );
			self.Events:RegisterEvent( 'GROUP_JOINED' );

			self.Events:SetScript( 'OnEvent',function( self,Event )
				C_Timer.After( 2, function()
					Addon.APP:ParseIgnores();
					Addon.APP:ParseMembers();

					if( #Addon.APP:GetPartyMembers() > 0 and #Addon.APP:GetIgnores() > 0 ) then
						for _,Ignore in pairs( Addon.APP:GetIgnores() ) do
							for _,Member in pairs( Addon.APP:GetPartyMembers() ) do
								if( Addon:Minify( Ignore ):find( Addon:Minify( Member ) ) ) then
									UIErrorsFrame:AddMessage( Ignore..' is ignored and is also in your group',AlertColor.r,AlertColor.g,AlertColor.b,AlertColor.a );
								end
							end
						end
					end
				end );
			end );

			C_Timer.After( 2, function()
				Addon.APP:ParseIgnores();
				Addon.APP:ParseMembers();

				if( #self:GetPartyMembers() > 0 and #self:GetIgnores() > 0 ) then
					for _,Ignore in pairs( self:GetIgnores() ) do
						for _,Member in pairs( self:GetPartyMembers() ) do
							if( Addon:Minify( Ignore ):find( Addon:Minify( Member ) ) ) then
								UIErrorsFrame:AddMessage( Ignore..' is ignored and is also in your group',AlertColor.r,AlertColor.g,AlertColor.b,AlertColor.a );
							end
						end
					end
				end
			end );
		end

		self:Init();

		self:UnregisterEvent( 'ADDON_LOADED' );
    end
end );