function(doc) {
    if ( doc.mentioning ) {
        doc.mentioning.map(function(tag) {
            emit(tag, null);
        });
    }
}
