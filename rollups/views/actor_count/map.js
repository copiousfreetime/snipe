function(doc) {
    if ( doc.actor ) {
        emit( doc.actor, null );
    }
}
