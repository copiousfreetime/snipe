function(doc) {
    if ( doc.source ) {
        emit( doc.source, doc._id );
    } 
}
