/**
 * Seeds Firebase Auth users + Firestore data for the 2048 app.
 *
 * Setup:
 *   1. Firebase Console → Project settings → Service accounts → Generate new private key
 *   2. Save as scripts/seed/serviceAccountKey.json (gitignored)
 *   3. cd scripts/seed && npm install && npm run seed
 *
 * Test logins (password for all): Test2048!
 *   alice.2048@test.com  → Alice
 *   bob.2048@test.com    → Bob
 *   carol.2048@test.com  → Carol
 */

import { readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import admin from 'firebase-admin';

const __dirname = dirname(fileURLToPath(import.meta.url));
const keyPath = join(__dirname, 'serviceAccountKey.json');
const useExisting = process.argv.includes('--existing');

if (!existsSync(keyPath)) {
  console.error(`
Missing serviceAccountKey.json

Download from Firebase Console:
  Project settings → Service accounts → Generate new private key
  Save to: scripts/seed/serviceAccountKey.json
`);
  process.exit(1);
}

const serviceAccount = JSON.parse(readFileSync(keyPath, 'utf8'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const auth = admin.auth();
const db = admin.firestore();

const SEED_PASSWORD = 'Test2048!';

const seedPlayers = [
  {
    email: 'alice.2048@test.com',
    nickname: 'Alice',
    profile: {
      highestScore: 8420,
      exp: 340,
      coins: 520,
      rank: 'Silver',
      wins: 12,
      losses: 8,
      totalGames: 24,
      highestTile: 1024,
      favoriteSkin: 'default',
    },
    runs: [
      { finalScore: 8420, maxTile: 1024, won: false, mode: 'single', daysAgo: 0 },
      { finalScore: 6100, maxTile: 512, won: false, mode: 'single', daysAgo: 1 },
      { finalScore: 3200, maxTile: 256, won: false, mode: 'single', daysAgo: 3 },
    ],
  },
  {
    email: 'bob.2048@test.com',
    nickname: 'Bob',
    profile: {
      highestScore: 12040,
      exp: 520,
      coins: 890,
      rank: 'Gold',
      wins: 28,
      losses: 15,
      totalGames: 45,
      highestTile: 2048,
      favoriteSkin: 'neon',
    },
    runs: [
      { finalScore: 12040, maxTile: 2048, won: true, mode: 'single', daysAgo: 0 },
      { finalScore: 9800, maxTile: 1024, won: false, mode: 'single', daysAgo: 2 },
      { finalScore: 4500, maxTile: 512, won: false, mode: 'online', daysAgo: 5 },
    ],
  },
  {
    email: 'carol.2048@test.com',
    nickname: 'Carol',
    profile: {
      highestScore: 5600,
      exp: 180,
      coins: 240,
      rank: 'Bronze',
      wins: 5,
      losses: 9,
      totalGames: 14,
      highestTile: 512,
      favoriteSkin: 'dark',
    },
    runs: [
      { finalScore: 5600, maxTile: 512, won: false, mode: 'single', daysAgo: 1 },
      { finalScore: 2100, maxTile: 128, won: false, mode: 'single', daysAgo: 4 },
    ],
  },
];

const existingEmails = [
  'faiza11@gmail.com',
  'basit.ul.ibad@gmail.com',
  'balanceo450@gmail.com',
  'eman@gmail.com',
  'faizamunir501@gmail.com',
];

function daysAgoTimestamp(days) {
  const d = new Date();
  d.setDate(d.getDate() - days);
  return admin.firestore.Timestamp.fromDate(d);
}

async function getOrCreateAuthUser(email, displayName) {
  try {
    const existing = await auth.getUserByEmail(email);
    console.log(`  Auth exists: ${email} (${existing.uid})`);
    return existing;
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    const user = await auth.createUser({
      email,
      password: SEED_PASSWORD,
      displayName,
      emailVerified: true,
    });
    console.log(`  Auth created: ${email} (${user.uid})`);
    return user;
  }
}

async function seedUserProfile(uid, email, nickname, profile, runs) {
  const userRef = db.collection('users').doc(uid);

  await userRef.set(
    {
      nickname,
      email,
      highestScore: profile.highestScore,
      currentLevel: Math.max(1, Math.floor(profile.exp / 100) + 1),
      exp: profile.exp,
      coins: profile.coins,
      rank: profile.rank,
      wins: profile.wins,
      losses: profile.losses,
      friendsCount: 0,
      totalGames: profile.totalGames,
      highestTile: profile.highestTile,
      favoriteSkin: profile.favoriteSkin,
      isOnline: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await db.collection('nickname_index').doc(nickname).set({ userId: uid });

  await userRef.collection('user_skins').doc('owned').set({
    skins: ['default', profile.favoriteSkin].filter((v, i, a) => a.indexOf(v) === i),
    selected: profile.favoriteSkin,
  });

  const runsCol = userRef.collection('runs');
  const existingRuns = await runsCol.limit(1).get();
  if (existingRuns.empty) {
    for (const run of runs) {
      await runsCol.add({
        finalScore: run.finalScore,
        maxTile: run.maxTile,
        won: run.won,
        mode: run.mode,
        createdAt: daysAgoTimestamp(run.daysAgo),
      });
    }
    console.log(`    + ${runs.length} runs`);
  } else {
    console.log('    runs already present, skipped');
  }

  await db
    .collection('leaderboard')
    .doc('global')
    .collection('topPlayers')
    .doc(uid)
    .set(
      {
        userId: uid,
        nickname,
        highestScore: profile.highestScore,
        level: Math.max(1, Math.floor(profile.exp / 100) + 1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  return uid;
}

async function seedSocial(aliceUid, bobUid, carolUid) {
  const pending = await db
    .collection('friend_requests')
    .where('senderId', '==', bobUid)
    .where('receiverId', '==', aliceUid)
    .where('status', '==', 'pending')
    .limit(1)
    .get();

  if (pending.empty) {
    await db.collection('friend_requests').add({
      senderId: bobUid,
      receiverId: aliceUid,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('  + friend request Bob → Alice (pending)');
  }

  await db.collection('party_rooms').add({
    roomCode: 'PLAY42',
    hostId: aliceUid,
    guestId: null,
    roomStatus: 'waiting',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log('  + party room PLAY42 (waiting)');

  const notifications = [
    {
      receiverId: aliceUid,
      type: 'friend_request',
      title: 'New friend request',
      message: 'Bob wants to be your friend!',
    },
    {
      receiverId: aliceUid,
      type: 'rank_promotion',
      title: 'Rank up!',
      message: 'You reached Silver rank. Keep playing!',
    },
    {
      receiverId: bobUid,
      type: 'match_invite',
      title: 'Quick match',
      message: 'Carol is online — challenge them?',
    },
  ];

  for (const n of notifications) {
    await db.collection('notifications').add({
      ...n,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  console.log(`  + ${notifications.length} notifications`);
}

async function seedExistingUsers() {
  console.log('\nBackfilling existing Auth users from your project...\n');
  const uids = [];
  for (const email of existingEmails) {
    try {
      const user = await auth.getUserByEmail(email);
      const nickname =
        user.displayName ||
        email.split('@')[0].replace(/\./g, '_').slice(0, 12);
      const profile = {
        highestScore: 2000 + Math.floor(Math.random() * 6000),
        exp: 100 + Math.floor(Math.random() * 400),
        coins: 100 + Math.floor(Math.random() * 300),
        rank: 'Bronze',
        wins: 3,
        losses: 2,
        totalGames: 8,
        highestTile: 256,
        favoriteSkin: 'default',
      };
      const runs = [
        {
          finalScore: profile.highestScore,
          maxTile: profile.highestTile,
          won: false,
          mode: 'single',
          daysAgo: 0,
        },
      ];
      await seedUserProfile(user.uid, email, nickname, profile, runs);
      uids.push(user.uid);
      console.log(`  ✓ ${email} → ${nickname}`);
    } catch (e) {
      console.log(`  ✗ ${email}: ${e.message}`);
    }
  }
  return uids;
}

async function main() {
  console.log('2048 Firestore + Auth seed\n');

  let aliceUid, bobUid, carolUid;

  if (useExisting) {
    await seedExistingUsers();
    console.log('\nDone (--existing). Run without flag to also create Alice/Bob/Carol test accounts.');
    process.exit(0);
  }

  console.log('Creating seed players...\n');
  const uids = {};
  for (const player of seedPlayers) {
    console.log(player.nickname);
    const authUser = await getOrCreateAuthUser(player.email, player.nickname);
    uids[player.nickname] = await seedUserProfile(
      authUser.uid,
      player.email,
      player.nickname,
      player.profile,
      player.runs,
    );
  }

  aliceUid = uids.Alice;
  bobUid = uids.Bob;
  carolUid = uids.Carol;

  console.log('\nSocial + demo data...');
  await seedSocial(aliceUid, bobUid, carolUid);

  console.log(`
✅ Seed complete!

Test accounts (password: ${SEED_PASSWORD}):
  alice.2048@test.com  / Alice
  bob.2048@test.com    / Bob
  carol.2048@test.com  / Carol

To backfill your existing Console users:
  npm run seed:existing
`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
