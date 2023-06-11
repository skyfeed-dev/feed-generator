// ! This file contains all SurrealQL queries used for @skyfeed.xyz custom feeds

final surrealQueries = {
  // ! Discover: Posts a user might enjoy, based on like history. Works by collecting your past likes of less popular posts, searching the network for users who have a similar like history, aggregating their recent likes and then ranking based on the sum of all the curator weights.
  'discover':
      r'''LET $liked_posts = (SELECT ->(like WHERE createdAt > (time::now() - 168h) AND meta::tb(out) == 'post') as likes FROM $feeduserdid).likes.out;
LET $liked_posts2 = (SELECT * FROM (SELECT id, type::thing('like_count_view', [id]).likeCount AS likeCount FROM $liked_posts) WHERE likeCount > 1 ORDER BY likeCount ASC LIMIT 64).id;

LET $tmp1 = array::flatten((SELECT <-like<-did AS curators FROM $liked_posts2).curators);
LET $curators = SELECT id,score FROM (SELECT id,count() as score FROM $tmp1 GROUP BY id) WHERE id != $feeduserdid ORDER BY score DESC LIMIT 64;

-- This blocklist contains DIDs with more than 10k likes in the last 7 days (for example the Love Fairy), because if a feed user liked a post one of them liked too, they have a significant performance impact and provide no value to the algorithm (because it depends on curation based on matching likes, and users who just like half the posts on the network don't really provide value for this method)
LET $blocklist = [did:plc_xxno7p4xtpkxtn4ok6prtlcb,did:plc_nykin5up57yvdzicmonul4uk,did:plc_z6srowwqbz4srzh4vxqigdp5];

LET $curators_filtered = SELECT id,score FROM $curators WHERE $blocklist CONTAINSNOT id;

LET $new_likes = SELECT *,->(like WHERE createdAt > (time::now() - 6h) AND meta::tb(out) == 'post') as likes FROM $curators_filtered;
LET $another_var = SELECT id,score,(SELECT out, createdAt from $parent.likes ORDER BY createdAt DESC LIMIT 32).out AS likes FROM $new_likes;

LET $posts = array::flatten((SELECT (SELECT id, $parent.score AS score FROM $parent.likes) AS posts FROM $another_var).posts);
LET $liked_posts4 = SELECT id, math::sum(score) as totalScore FROM $posts GROUP BY id ORDER BY totalScore DESC LIMIT 500;
SELECT id FROM $liked_posts4 WHERE $liked_posts CONTAINSNOT id;
''',

// ! Feed of Feeds: All posts which embed a custom feed
  'feed-of-feeds': r'''
SELECT id,createdAt FROM post WHERE record != NONE AND meta::tb(record) == 'feed' ORDER BY createdAt DESC LIMIT 1000;
''',

// ! Catch Up: Most liked posts from the last 24 hours
  'catch-up':
      r'select subject as id, likeCount from like_count_view where likeCount > 68 and subject.createdAt > (time::now() - 24h) order by likeCount desc limit 1000;',

  // ! Catch Up Weekly: Most liked posts from the last 7 days
  'catch-up-weekly':
      r'select subject as id, likeCount from like_count_view where likeCount > 130 and subject.createdAt > (time::now() - 168h) order by likeCount desc limit 1000;',

  // ! Art New: Powers the @bsky.art feed
  'art-new':
      r'''LET $artists = (select ->follow.out as following from did:plc_y7crv2yh74s7qhmtx3mvbgv5).following;
LET $posts = array::flatten(array::flatten((SELECT (SELECT ->posts.out as posts FROM $parent.id) AS posts FROM $artists).posts.posts));
LET $reposts = (SELECT ->repost.out as reposts FROM did:plc_y7crv2yh74s7qhmtx3mvbgv5).reposts;
LET $hashtag_posts = (SELECT ->usedin.out AS posts FROM hashtag:art).posts;
return SELECT id,createdAt FROM array::distinct(array::concat($hashtag_posts,array::concat($posts,$reposts))) WHERE count(images) > 0 ORDER BY createdAt DESC LIMIT 1000;
''',

  // ! Mutuals: Posts from mutual follows
  'mutuals':
      r'''LET $res = (select ->follow.out as following, <-follow.in as follows from $feeduserdid);
LET $mutuals = array::intersect($res.follows, $res.following);
SELECT id,createdAt FROM array::flatten(array::flatten((SELECT (SELECT ->(posts WHERE createdAt > (time::now() - 168h)).out as posts FROM $parent.id) AS posts FROM $mutuals).posts.posts)) ORDER BY createdAt DESC LIMIT 1000;''',
  // ! Re+Posts: Posts and Reposts from people you are following
  're-plus-posts': r'''
LET $following = (select ->follow.out as following FROM $feeduserdid).following;

LET $reposts = SELECT id as repost,out as id,createdAt FROM array::flatten(array::flatten((SELECT (SELECT ->(repost WHERE createdAt > (time::now() - 24h)) as reposts FROM $parent.id) AS reposts FROM $following).reposts.reposts));
LET $posts = SELECT id,createdAt FROM array::flatten(array::flatten((SELECT (SELECT ->(posts WHERE createdAt > (time::now() - 24h)).out as posts FROM $parent.id) AS posts FROM $following).posts.posts));

SELECT * FROM array::concat($reposts,$posts) ORDER BY createdAt DESC LIMIT 1000;
''',

  // ! OnlyPosts: Only posts from people you are following, nothing else
  'only-posts':
      r'''LET $following = (select ->follow.out as following FROM $feeduserdid).following;
SELECT id,createdAt FROM array::flatten(array::flatten((SELECT (SELECT ->(posts WHERE createdAt > (time::now() - 72h)).out as posts FROM $parent.id) AS posts FROM $following).posts.posts)) ORDER BY createdAt DESC LIMIT 1000;''',

  // ! What's warm: Posts with 6+ likes from the last hour
  'whats-warm':
      r'SELECT subject as id, subject.createdAt as createdAt FROM like_count_view WHERE likeCount > 5 AND subject.createdAt > (time::now() - 1h) order by createdAt desc;',

  // ! What's Reposted: Posts with 5+ reposts
  'whats-reposted':
      'select id,createdAt from post where parent == NONE and createdAt > (time::now() - 6h) and count(<-repost) > 4 order by createdAt desc;',
};
