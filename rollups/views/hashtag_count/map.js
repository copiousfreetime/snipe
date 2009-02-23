function(doc) {
    if ( doc.hashtags ) {
        doc.hashtags.map(function(tag) {
            emit(tag, null);
        });
    }
}
