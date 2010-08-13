require "fat_free_crm"

FatFreeCRM::Plugin.register(:auto_complete_accounts, initializer) do
          name "Auto Complete Accounts"
       authors "Gerrit Riessen"
       version "0.1"
   description "Adds autocomplete to the accounts field"
  dependencies :simple_column_search, :auto_complete 
end

require File.dirname(__FILE__)+'/lib/auto_complete_accounts.rb'
