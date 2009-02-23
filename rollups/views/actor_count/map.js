function(doc) {
    if ( doc.actor ) {
        emit( doc.actor, doc._id );
    }
}
