function(doc) {
    if ( doc.source ) {
        emit( doc.source, null );
    }
}
