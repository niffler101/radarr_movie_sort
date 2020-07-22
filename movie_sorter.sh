#!/bin/bash

# set current working directory to directory of the script
cd "$(dirname "$0")"

# load .env file
source .env

########## SCRIPT VARIABLES

# Assign radarr_movie_json from imported movie from Radarr API
radarr_movie_json=$(curl -X GET "$RADARR_DOMAIN/api/v3/movie/$radarr_movie_id?apikey=$RADARR_API_KEY")
sleep 2s

# Assign "radarr_movie_imdb_ID"
radarr_movie_imdb_ID=$(echo "$radarr_movie_json" | jq --raw-output '.imdbId')

# Assign "radarr_movie_title"
radarr_movie_title=$(echo "$radarr_movie_json" | jq --raw-output '.title')

# Assign "radarr_movie_title"
radarr_movie_year=$(echo "$radarr_movie_json" | jq --raw-output '.year')

# Assign radarr_movie_current_path to original imported path
radarr_movie_current_path=$(echo "$radarr_movie_json" | jq --raw-output '.path')

# Assign radarr_movie_tmdb_json from TMDB API GET
radarr_movie_tmdb_json=$(curl -X GET "https://api.themoviedb.org/3/movie/$radarr_movie_imdb_ID?api_key=$TMDB_API_KEY&language=en-US&append_to_response=keywords")
sleep 2s

# Assign radarr_movie_tmdb_genres & radarr_movie_tmdb_keywords from tmdbapi JSON
radarr_movie_tmdb_genres=$(echo "$radarr_movie_tmdb_json" | jq -r '.genres[].name ')
radarr_movie_tmdb_keywords=$(echo "$radarr_movie_tmdb_json" | jq -r '.keywords.keywords[].name')

# Copy radarr_movie_current_path to working_path
working_path=$radarr_movie_current_path

########## User Selectable Function

# Remove all words in "WORDS_TO_REMOVE" array in .env from the front of movie title
remove_words () {
    if [[ $REMOVE_THE_WORDS == TRUE ]]; then
        for i in "${!WORDS_TO_REMOVE[@]}"; do
            word=${WORDS_TO_REMOVE[$i]}
            length=$((${#word}  + 1))
            the_present=${radarr_movie_title:0:$length}
            word_to_remove="$word "
            if [ "$the_present" = "$word_to_remove" ]; then
                remove_movie_path=$(echo "${radarr_movie_current_path//$word_to_remove/}, $word")
                working_path=$remove_movie_path
                break
            fi
        done
    fi
}

# Filter movies by genres in "FILTER_GENRE_JSON" in .env and creates new path with related defined folder
filter_genres () {
    if [[ $FILTER_GENRES == TRUE ]]; then
        for row in $(echo "${FILTER_GENRE_JSON}" | jq -r '.[] | @base64'); do
            _jq() {
                echo ${row} | base64 --decode | jq -r ${1}
            }
            user_genre_folder=$(echo $(_jq '.folder'))
            user_genre_genre=$(echo $(_jq '.genre'))
            if [[ $radarr_movie_tmdb_genres == *"$user_genre_genre"* ]]; then
                # set the string to swap out in path
                new_movie_path_swap_string="$ROOT_PATH/$user_genre_folder"
                initiate_move
                exit
            fi
        done
    fi
}

# Filter movies by keywords in "FILTER_KEYWORD_JSON" in .env and creates new path with related defined folder
filter_keywords () {
    if [[ $FILTER_KEYWORDS == TRUE ]]; then
        for row in $(echo "${FILTER_KEYWORD_JSON}" | jq -r '.[] | @base64'); do
            _jq() {
                echo ${row} | base64 --decode | jq -r ${1}
            }
            user_keyword_folder=$(echo $(_jq '.folder'))
            user_keyword_keyword=$(echo $(_jq '.keyword'))
            if [[ $radarr_movie_tmdb_keywords == *"$user_keyword_keyword"* ]]; then
                # set the string to swap out in path
                new_movie_path_swap_string="$ROOT_PATH/$user_keyword_folder"
                initiate_move
                exit
            fi
        done
    fi    
}

# Filter movies by year period in "YEARS_TO_SORT_JSON" in .env and creates new path with related defined folder
sort_years () {
    if [[ $SORT_YEARS == TRUE ]]; then
        for row in $(echo "${YEARS_TO_SORT_JSON}" | jq -r '.[] | @base64'); do
            _jq() {
                echo ${row} | base64 --decode | jq -r ${1}
            }
            start_year=$(echo $(_jq '.start_year'))
            end_year=$(echo $(_jq '.end_year'))
            folder=$(echo $(_jq '.folder'))
            if [[ "$radarr_movie_year" -ge "$start_year" && "$radarr_movie_year" -le "$end_year" ]]; then
                # set the string to swap out in path
                new_movie_path_swap_string="$ROOT_PATH/$folder"
                initiate_move
                exit
            fi
        done
    fi    
}

########## Essential Function

# Assign movie a new path ready for Radarr API PUT
assign_new_movie_path () {
    new_movie_path=$(echo "${working_path/"$ROOT_PATH$EXTRA_PATH"/$new_movie_path_swap_string}")
}

# Move movie folder & contents to the movie's new path
move_folders () {
    mv -v "$radarr_movie_current_path" "$new_movie_path"
}

# Set movie's new JSON with updated path & folderName and PUT to Radarr API
set_json_and_PUT () {
    new_movie_json=$(echo "$radarr_movie_json" | jq --arg mnp "$new_movie_path" --arg mnf "$new_movie_path" '. + {path:$mnp, folderName:$mnf}')
    curl -s -X PUT -H "Content-Type: application/json" -d "$new_movie_json" $RADARR_DOMAIN/api/v3/movie/$radarr_movie_id?apikey=$RADARR_API_KEY
}

# Fuction to run above 3 Essential Functions.
initiate_move () {
    assign_new_movie_path
    move_folders
    set_json_and_PUT
}

# Declares the array of WORDS_TO_REMOVE from .env
declare -a WORDS_TO_REMOVE

# Declares the RUN_ORDER array from .env. 
declare -a RUN_ORDER

# Runs the functions/filters in order defined in RUN_ORDER in the .env
for i in "${!RUN_ORDER[@]}"; do
    ${RUN_ORDER[$i]};
done

exit