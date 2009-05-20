require('json')

function _begin()
    _log("snipe methods started")
end

function _end()
    _log("snipe methods ended")
end

-- update the count that is at key 'branch/key' with a new value
function _update_count( branch, key )
    local count_key = branch .. "/" .. key

    _lock( count_key )
    local o_val = tonumber( _get( count_key ) )
    local n_val = 1
    if o_val then
        n_val = o_val + 1
    end
    _put( count_key, tostring( n_val ) )
    _unlock( count_key )
    return nil
end

-- update the json list keyed by 'list' with the new item 
function _update_list( list, new_item )
    local t = {}

    _lock( list )
    local js = _get( list )
    if js then
        t = json.decode( js )
    end
    t[new_item] = true
    _put( list, json.encode( t ) )
    _unlock( list )
    return nil
end

-- update author meta information
function _update_author_meta( author )
    _update_count( 'author', author )
    _update_list( 'authors', author )
end

-- update source meta information
function _update_source_meta( source )
    _update_count( 'source', source )
    _update_list( 'sources', source )
end

-- update the meta information for this entry
function _update_meta( entry )
    _update_author_meta( entry.author )
    _update_source_meta( entry.source )
end

-- store the raw tweet and update the meta information
function store_tweet(key, value)
    _put( key, value )
    _update_meta( json.decode( value ) )

    return "ok"
end

