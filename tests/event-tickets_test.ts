import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test ticket minting",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      // Deployer can mint ticket
      Tx.contractCall('event-tickets', 'mint-ticket', [
        types.ascii("Concert 2024"),
        types.uint(100)
      ], deployer.address),
      
      // Regular user cannot mint ticket
      Tx.contractCall('event-tickets', 'mint-ticket', [
        types.ascii("Concert 2024"),
        types.uint(100)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(0);
    block.receipts[1].result.expectErr(types.uint(100));
  }
});

Clarinet.test({
  name: "Test ticket listing and purchase",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    
    // First mint a ticket
    let block = chain.mineBlock([
      Tx.contractCall('event-tickets', 'mint-ticket', [
        types.ascii("Concert 2024"),
        types.uint(100)
      ], deployer.address)
    ]);
    
    // List ticket for sale
    block = chain.mineBlock([
      Tx.contractCall('event-tickets', 'list-ticket', [
        types.uint(0),
        types.uint(200)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Buy ticket
    block = chain.mineBlock([
      Tx.contractCall('event-tickets', 'buy-ticket', [
        types.uint(0)
      ], buyer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
