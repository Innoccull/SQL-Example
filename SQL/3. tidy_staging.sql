-- Script to tidy up data in staging before loading to star schema

  UPDATE stg_matches
  SET team1_players = REPLACE(team1_players, 'S Fouch\u00c3\u00a9', 'S Fouche')
  WHERE team1_players like '%S Fouch\u00c3\u00a9%'

  UPDATE stg_matches
  SET team2_players = REPLACE(team2_players, 'S Fouch\u00c3\u00a9', 'S Fouche')
  WHERE team2_players like '%S Fouch\u00c3\u00a9%'

  UPDATE stg_deliveries
  SET batter = REPLACE(batter, 'S Fouché', 'S Fouche')
  WHERE batter like '%S Fouché%'

  UPDATE stg_deliveries
  SET bowler = REPLACE(bowler, 'S Fouché', 'S Fouche')
  WHERE bowler like '%S Fouché%'

  UPDATE stg_deliveries
  SET non_striker = REPLACE(non_striker, 'S Fouché', 'S Fouche')
  WHERE non_striker like '%S Fouché%'

  UPDATE stg_wickets
  SET player_out = REPLACE(player_out, 'S Fouché', 'S Fouche')
  WHERE player_out like '%S Fouché%'
