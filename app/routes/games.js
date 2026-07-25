import { ProtectedRoute } from 'ec/utils/routes';

/**
 * GamesRoute is the guard for everything under /games.
 *
 * There is no game-master guard here or on any child. Whether a signed-in
 * account may see a game, and whether it may set one up, are decisions the
 * server makes from the seat it holds — a route guard could only repeat what
 * the server already refuses, and would be wrong the moment a seat changed.
 */
export default class GamesRoute extends ProtectedRoute {}
