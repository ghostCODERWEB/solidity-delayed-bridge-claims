export async function suite(h) {
  const token = await h.token();
  const c = await h.deploy("DelayedBridgeEscrow", [
    token.target,
    20,
    h.addresses[0],
  ]);
  await h.tx(token.approve(c.target, 1000));
  const message = h.ethers.id("source-message");
  const root = await c.messageLeaf(1, message, h.addresses[1], 100);
  await h.tx(c.publish(1, root, 100));
  await h.test("only owner publishes roots", () =>
    h.revert(() => c.connect(h.signers[1]).publish(2, root, 100)),
  );
  await h.test("delay blocks immediate claims", () =>
    h.revert(() => c.release(1, message, h.addresses[1], 100, [])),
  );
  await h.test("bad recipient proof rejected", async () => {
    await h.mine(21);
    await h.revert(() => c.release(1, message, h.addresses[2], 100, []));
  });
  await h.test("activated claim releases token", async () => {
    await h.tx(c.release(1, message, h.addresses[1], 100, []));
    h.eq(await token.balanceOf(h.addresses[1]), 100n);
    h.eq(await c.liability(), 0n);
  });
  await h.test("message cannot replay", () =>
    h.revert(() => c.release(1, message, h.addresses[1], 100, [])),
  );
  await h.test("pending root cancellation refunds budget", async () => {
    await h.tx(c.publish(2, root, 50));
    await h.tx(c.cancel(2));
    h.eq((await c.batches(2)).cancelled, true);
  });
}
